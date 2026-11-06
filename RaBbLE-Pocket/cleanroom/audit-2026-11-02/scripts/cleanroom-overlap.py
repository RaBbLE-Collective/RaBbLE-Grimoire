#!/usr/bin/env python3
# Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.
#
# Clean-room overlap gate. INTEGRATOR ONLY: this reads the Muse Gadget SDK,
# so an implementer must never run it or see its per-line output.
#
# RETIRED after W6 (S277): the reference SDK is deleted, so the script exits early
# until it is re-cloned into third_party/muse-gadget-sdk. The logic stays for
# future clean rooms.
#
# Counts "substantive" lines of each given file (normalised whitespace, over
# 12 characters, not comments, braces or includes) and how many occur
# verbatim anywhere in the SDK's C/C++ sources. Plan:
# RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md (gate: <5%).
#
#   ops/cleanroom-overlap.py [--sdk DIR] [--show] FILE...
import argparse, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SDK = os.path.join(HERE, "..", "third_party", "muse-gadget-sdk", "esp32")
EXT = (".c", ".h", ".cc", ".cpp", ".hpp")


def norm(line):
    return re.sub(r"\s+", " ", line).strip()


def substantive(text):
    text = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)
    for raw in text.splitlines():
        s = norm(re.sub(r"//.*$", "", raw))
        if len(s) <= 12 or s.startswith("#include"):
            continue
        if re.fullmatch(r"[{}();,\s]*", s) or s in ("} else {", "default: break;"):
            continue
        yield s


def sdk_lines(root):
    seen = set()
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if not d.startswith("build") and d not in ("avatar", ".git", "managed_components")]
        for f in fn:
            if f.endswith(EXT):
                try:
                    seen.update(substantive(open(os.path.join(dp, f), errors="replace").read()))
                except OSError:
                    pass
    return seen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sdk", default=SDK)
    ap.add_argument("--show", action="store_true", help="print matching lines (integrator eyes only)")
    ap.add_argument("files", nargs="+")
    a = ap.parse_args()
    if not os.path.isdir(a.sdk):
        print(
            "cleanroom-overlap: retired. The reference SDK was deleted after W6 (S277).\n"
            f"No SDK at {a.sdk}. To rerun the gate, re-clone it into "
            f"{os.path.normpath(SDK)} (see third_party/README.md), "
            "or pass --sdk DIR for another clean room.",
            file=sys.stderr,
        )
        sys.exit(2)
    ref = sdk_lines(a.sdk)
    if not ref:
        sys.exit(f"no SDK sources under {a.sdk}")
    tot = hit = 0
    for path in a.files:
        lines = list(substantive(open(path, errors="replace").read()))
        m = [l for l in lines if l in ref]
        tot += len(lines); hit += len(m)
        pct = 100.0 * len(m) / len(lines) if lines else 0.0
        print(f"{pct:5.1f}%  {len(m):4d}/{len(lines):<4d} {path}")
        if a.show:
            for l in m:
                print(f"         | {l}")
    pct = 100.0 * hit / tot if tot else 0.0
    print(f"{pct:5.1f}%  {hit:4d}/{tot:<4d} total")
    sys.exit(0 if pct < 5.0 else 1)  # 2 = retired (no SDK), see above


if __name__ == "__main__":
    main()
