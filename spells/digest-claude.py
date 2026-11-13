#!/usr/bin/env python3
"""digest-claude.py : turn Claude Code transcripts into a durable per-session digest.

Reads   <archive>/projects/*/*.jsonl   (default archive: ~/claude-archive, filled by harvest-claude.sh)
Writes  <archive>/digest/sessions.jsonl   one JSON object per session, upserted by session id

The digest is the layer that outlives the raw transcripts: project, dates, title, models,
token buckets per model (so dollars can be recomputed when prices change), and the human's
own typed prompts. Existing records are never deleted, so cost and prompt history persist
even after the transcript is gone. A session whose transcript grew is re-digested in place.

Also seeds priced-only records from Grimoire/log/token-viz.json (June 2026 history whose
transcripts no longer exist); those carry source="token-viz" and never overwrite a
transcript-derived record.

Subagent transcripts (<session>/subagents/) are folded into their parent session's tokens.
Token counts are de-duplicated by message id (a streamed reply is logged once per content
block, each repeating the same usage). score-token-viz.py does not de-duplicate, so its
totals run higher than these.

Private by design: prompts can contain pasted secrets. Archive dir is mode 700; run gitleaks
before anything from it goes near a repo.

Usage: digest-claude.py [--archive DIR] [--quiet]
"""
import argparse
import datetime
import json
import os
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
GRIMOIRE = HERE.parent
PROMPT_CAP = 4000

for cand in (pathlib.Path.home() / ".config/waybar/scripts",
             GRIMOIRE.parent / "RaBbLE-OS/config/waybar/scripts"):
    if (cand / "score_pricing.py").exists():
        sys.path.insert(0, str(cand))
        break
try:
    import score_pricing
except ImportError:
    score_pricing = None


def short_model(m):
    return (m or "").replace("claude-", "").replace("-20251001", "")


def project_name(dirname):
    if dirname.endswith("-RaBbLE-Collective"):
        return "RaBbLE-Collective"
    if "-RaBbLE-" in dirname:
        return "RaBbLE-" + dirname.split("-RaBbLE-", 1)[1]
    return dirname.replace("-home-rabble-", "")


def ts_of(row):
    raw = row.get("timestamp")
    if raw:
        try:
            return datetime.datetime.fromisoformat(str(raw).replace("Z", "+00:00")).timestamp()
        except ValueError:
            pass
    return None


def human_text(row):
    msg = row.get("message") or {}
    c = msg.get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        parts = [b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"]
        return "\n".join(p for p in parts if p)
    return ""


def src_size(jl):
    subs = (jl.parent / jl.stem / "subagents").glob("*.jsonl")
    return jl.stat().st_size + sum(f.stat().st_size for f in subs)


def digest_one(jl):
    first = last = None
    title = cwd = branch = None
    prompts, seen_msgs = [], {}
    edited = set()
    subs = sorted((jl.parent / jl.stem / "subagents").glob("*.jsonl"))
    lines = (l for f in [jl, *subs] for l in open(f, errors="replace"))
    for line in lines:
        try:
            row = json.loads(line)
        except ValueError:
            continue
        t = ts_of(row)
        if t:
            first = t if first is None else min(first, t)
            last = t if last is None else max(last, t)
        kind = row.get("type")
        cwd = cwd or row.get("cwd")
        branch = row.get("gitBranch") or branch
        if kind == "ai-title":
            title = row.get("aiTitle") or row.get("title") or title
        elif kind == "user" and (row.get("origin") or {}).get("kind", "human") == "human":
            txt = human_text(row).strip()
            if txt and not txt.startswith("<"):
                prompts.append({"ts": row.get("timestamp"), "text": txt[:PROMPT_CAP]})
        elif kind == "assistant":
            msg = row.get("message") or {}
            u = msg.get("usage") or {}
            mid = msg.get("id") or row.get("uuid")
            if u and mid:
                seen_msgs[mid] = (short_model(msg.get("model")), u)
            c = msg.get("content")
            if isinstance(c, list):
                for b in c:
                    if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in ("Edit", "Write", "NotebookEdit"):
                        fp = (b.get("input") or {}).get("file_path")
                        if fp:
                            edited.add(fp)
    models = {}
    for model, u in seen_msgs.values():
        if not model or model == "<synthetic>":
            continue
        b = models.setdefault(model, {"down": 0, "up": 0, "cache_read": 0, "cache_write": 0})
        b["down"] += u.get("input_tokens", 0) or 0
        b["up"] += u.get("output_tokens", 0) or 0
        b["cache_read"] += u.get("cache_read_input_tokens", 0) or 0
        b["cache_write"] += u.get("cache_creation_input_tokens", 0) or 0
    usd = None
    if score_pricing:
        usd = round(sum(score_pricing.cost(m, inp=b["down"], out=b["up"], cache_read=b["cache_read"],
                                           cache_write=b["cache_write"]) for m, b in models.items()), 4)
    return {
        "session": jl.stem,
        "source": "transcript",
        "project": project_name(jl.parent.name),
        "cwd": cwd,
        "branch": branch,
        "title": title,
        "first_ts": first,
        "last_ts": last,
        "date": datetime.datetime.fromtimestamp(last).strftime("%Y-%m-%d %H:%M") if last else None,
        "messages": len(seen_msgs),
        "models": models,
        "usd_list_price": usd,
        "files_edited": sorted(edited),
        "prompts": prompts,
        "subagent_files": len(subs),
        "src_size": src_size(jl),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", default=str(pathlib.Path.home() / "claude-archive"))
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    arch = pathlib.Path(a.archive)
    out_dir = arch / "digest"
    out_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    out = out_dir / "sessions.jsonl"

    db = {}
    if out.exists():
        for line in open(out):
            try:
                r = json.loads(line)
                db[r["session"]] = r
            except (ValueError, KeyError):
                pass

    added = updated = 0
    for jl in sorted((arch / "projects").glob("*/*.jsonl")):
        old = db.get(jl.stem)
        if old and old.get("source") == "transcript" and old.get("src_size") == src_size(jl):
            continue
        db[jl.stem] = digest_one(jl)
        added, updated = (added + 1, updated) if old is None else (added, updated + 1)

    seeded = 0
    viz = GRIMOIRE / "log/token-viz.json"
    if viz.exists():
        for s in json.load(open(viz)).get("sessions", []):
            if s["session"] in db:
                continue
            db[s["session"]] = {
                "session": s["session"], "source": "token-viz", "project": s.get("project"),
                "feature": s.get("feature"), "first_ts": s.get("first_ts"), "last_ts": s.get("last_ts"),
                "date": s.get("date"), "messages": s.get("messages"), "models": {
                    m: {k: v[k] for k in ("down", "up", "cache_read", "cache_write")}
                    for m, v in (s.get("models") or {}).items()},
                "usd_list_price": s.get("usd"), "prompts": [], "files_edited": [],
            }
            seeded += 1

    tmp = out.with_suffix(".tmp")
    with open(tmp, "w") as f:
        for r in sorted(db.values(), key=lambda r: r.get("last_ts") or 0):
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    os.chmod(tmp, 0o600)
    os.replace(tmp, out)
    if not a.quiet:
        dated = [r["date"] for r in db.values() if r.get("date")]
        print(f"digest: {len(db)} sessions ({added} new, {updated} refreshed, {seeded} seeded from token-viz)"
              f" {min(dated)} -> {max(dated)}  {out}")


if __name__ == "__main__":
    main()
