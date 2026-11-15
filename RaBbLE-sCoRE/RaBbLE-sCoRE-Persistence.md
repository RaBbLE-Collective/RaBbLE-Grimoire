# RaBbLE-sCoRE-Persistence: SQLite on Render, snapshots in Cloudflare R2

Canonical agent-facing doc. Source of truth is the code in `RaBbLE-sCoRE/server/` (`snapshot.py`, `db.py`, `storage.py`, `transcripts.py`); this doc was written from it on `new-horizons` (S340, uncommitted code at the time) and the docstring of `snapshot.py` is the shortest summary. If code and this doc disagree, the code wins: fix the doc.

Status: **code written, tested against a fake R2, never run against real R2, not deployed** (see Known gaps).

## 1. Why

- Render's free web service has no persistent disk: the filesystem is wiped on every deploy and restart (`RaBbLE-sCoRE-Architecture.md`, Deployment section).
- The working database is SQLite at `DATA_DIR/score.db` (`db.py`): users, invites, guest counters, R2 usage counters, meta. One connection, one lock, one process.
- R2 is the durable store. `snapshot.py` restores the db from R2 at boot and uploads a copy after writes.
- Transcripts are write-only training data, stored in R2 as batched objects (section 9).
- All `R2_*` unset = local-only mode (`snapshot.state == "disabled"`): everything works, nothing leaves the box. This is the laptop default.

## 2. The invariant

Mark's rule: **nothing may wipe or silently lose data. An R2 404 never means "start fresh".** Everything below serves it:

- No snapshot is ever overwritten or deleted by the writer that just restored from an older one.
- An empty or unverifiable restore turns uploads OFF; it never uploads an empty db over a good one.
- Every refusal logs loudly and is visible at `GET /api/v1/admin/inventory` (`r2.snapshots`, from `snapshot.status()`).
- Accepted loss: a hard crash loses the last ~30 s of db writes (debounce) and up to one transcript flush interval.

## 3. Startup restore decision table

`snapshot.try_restore()` (`snapshot.py:313`), called from the lifespan (`main.py:56`). "Local db" = `DATA_DIR/score.db` exists.

| Situation | Result | Uploads |
|---|---|---|
| R2 not configured | state `disabled` | off (local-only) |
| No local db, pointer ok, object verifies (integrity_check + sha256) | restore it; state `restored` | on |
| Pointer object missing or corrupt, retried `SNAPSHOT_POINTER_RETRIES` (3) x `SNAPSHOT_POINTER_RETRY_S` (1 s) | restore newest older snapshot that verifies as FALLBACK; state `restored` plus `fallback_hold` | **HOLD** (section 5) |
| Pointer JSON missing or corrupt | same fallback path, newest verifying snapshot | HOLD |
| Snapshots exist, none verifies | state `failed`; restore retried every `SNAPSHOT_RESTORE_RETRY_S` (300) | off |
| Bucket empty, `R2_ALLOW_FRESH_START` unset | state `failed` ("no snapshot found": wrong prefix, bucket or token scope look identical) | off |
| Bucket empty, `R2_ALLOW_FRESH_START=1`, no snapshot-looking object anywhere in the bucket, no `snapshots/INITIALIZED` | state `fresh` | on |
| Bucket empty, flag set, but `INITIALIZED` exists or a snapshot-looking key exists elsewhere | state `failed` (refused) | off |
| R2 read errors or budget spent during restore | state `failed`, retry loop | off |
| Local db present, `.restore-pending` marker exists | state `failed` (an earlier boot failed its restore) | off |
| Local db present, pointer unreadable | state `present` with `hold` set (shrink gate and fence have no baseline) | HOLD |
| Local db present, `snapshot_lineage` meta differs from pointer key (stale disk, laptop with prod env, legacy db with no lineage) | state `failed`; restore and MERGE local rows into the pointer's snapshot, then upload the union | after merge |
| Local db present, lineage matches pointer | state `present` | on |
| Local db present, pointer missing but marker exists | hold (pointer missing, bucket was initialised) | HOLD |

`.restore-pending` is written before the db opens and removed only after a successful restore, so a crash mid-restore stays `failed`.

## 4. Snapshot objects, pointer, fence

All keys sit under `R2_PREFIX` (default `score/`).

- **Snapshot**: `snapshots/score-g<gen 8 digits>-<UTC YYYYMMDDTHHMMSSZ>.db`. Written once with `If-None-Match: *` (create-only). Generation = 1 + max over listed keys, the pointer's key and `gen`. Legacy names (`score-<ts>.db`) count as generation 0.
- **Pointer**: `snapshots/latest.json`: `key, gen, writer (INSTANCE id), at, bytes, users, invites, sha256, protect[]`.
- **Fence**: the pointer is replaced with `If-Match: "<md5 of the pointer we last read or wrote>"` (the S3/R2 etag of a single-part PUT). An absent pointer uses `If-None-Match: *`. A 409/412 on a conditional PUT raises `PreconditionFailed` (`storage.py` `_check`); on an unconditional PUT it is an ordinary error.
- **Self-fence adoption** (`_put_pointer`): if the PUT landed but the response was lost, the next one gets 412. We GET the pointer; if `writer == INSTANCE` and its key is the key of our last PUT, adopt its etag and retry once. Anything else is a real fence.
- **Real fence** (`_fenced`): state `failed`, `.restore-pending` written, uploads off. The loop (or `stop()`) runs `try_restore`, which merges our local rows into the winner's lineage, then uploads the union.
- **Lineage**: db meta `snapshot_lineage` = pointer key the db was last restored from or uploaded as. `_diverged()` (`snapshot.py:381`) forces restore-and-merge for a present db that does not descend from the pointer. A fallback records the pointer key it stands in for.
- **Upload gates** (`_flush`, `snapshot.py:507`): db dirty, R2 configured, state not `failed`, budget not spent, no hold. Then: copy via sqlite backup API, `integrity_check`, shrink gate (local users or invites more than 10% below the baseline = HOLD; baseline = max of pointer counts and restored counts; `SNAPSHOT_ALLOW_SHRINK=1` bypasses). Order: snapshot PUT, pointer PUT, usage object PUT (`accounting/usage.json`, failure tolerated), `snapshots/INITIALIZED` marker (first success), prune.
- Debounce: upload when dirty for `SNAPSHOT_DEBOUNCE_S` (30). Shutdown: one final flush, after one re-merge if the restore had failed or we were fenced (`stop()`, up to two rounds).
- Bookkeeping writes (`meta_set`, R2 counters) pass `track=False` so counting a snapshot never causes another.

## 5. Fallback = HOLD

A degraded restore (anything other than the pointer's own object) restores the newest verifying older snapshot and **holds uploads**. Reason: uploading would make the older state the new pointer and prune the newer, possibly good, snapshots (NiBbLE review 2, H1, reproduced).

- Hold is persisted to `DATA_DIR/.restore-hold` and db meta `fallback_hold`. If neither persists, state goes `failed` and logs CRITICAL. A restart on the same disk reloads the hold.
- **Ack**: inspect R2 first (is the pointer's object really gone, or was it a transient error?). Then set `SNAPSHOT_ACCEPT_FALLBACK=<restored key>` (full key or just the filename; compared on the basename) and redeploy. On ack, uploads resume and the keys newer than the source (`protect`) go into the pointer's `protect` list.
- **Protect list**: keys in `pointer["protect"]` are never pruned and are carried forward in every later pointer.
- Remove `SNAPSHOT_ACCEPT_FALLBACK` afterwards; it is harmless once acked but stale.
- Note: ack requires a redeploy, which is a fresh disk. Writes taken while held are 503'd for credentials (section 7) and otherwise lost on that redeploy: this is why the gate exists.

## 6. Merge on late restore, retention

`db.replace_with(snapshot, merge_local)` (`db.py:177`). The restored snapshot is the base; local rows are folded in:

- `users` (key `id`), `invites` (key `token`): rows only local are inserted; rows on both sides: the newer `updated_at` wins per row (`migrations/0003_updated_at.sql`; fixed-width UTC ISO from `db.now_ts()`, so string order is time order; `users.py` sets it on save, invite save, consume).
- Invite `consumed` / `consumed_by` are monotone: once consumed on either side, consumed (a single-use invite never becomes reusable); `consumed_by` fills only if NULL.
- Counters are `MAX`: `guest_turns`, `guest_turns_by_user`, `guest_issue`, `r2_usage`. A late restore never resets a daily cap or hourly issuance limit.
- `meta`: `INSERT OR IGNORE`, restored values win.
- Both dbs are migrated first (`_migrate`), so an older local db merges cleanly.
- Not covered: handle collisions across a merge (two rows with the same handle, different ids): NiBbLE L2, carried over, untouched. Unverified whether anything guards it.

Retention (`_keep_set`, runs after each successful upload, never touches the new key, the pointer's key or any `protect` key): newest `SNAPSHOT_KEEP` (8), plus the first snapshot of each hour for `SNAPSHOT_KEEP_HOURLY_H` (48) hours, plus the first of each day for `SNAPSHOT_KEEP_DAILY_D` (90) days. Names with no parseable timestamp are kept. Retention trusts the wall clock (a forward step over 90 d would prune to the newest 8 plus protect). DELETE is free and uncounted.

## 7. The 503 gate

`auth_routes._require_durable()` (`auth_routes.py:98`) returns HTTP 503 with `Retry-After: 300` and "nothing was saved" when `snapshot.uploads_enabled()` is false (state `failed`, any `hold`, or a fallback hold). Applied to: legacy register, admin invite create, summon, guest issue (`/users/guest`), profile update. Guest issue also 503s when the R2 budget is spent, and 429s over `GUEST_ISSUE_PER_HOUR`.

Reason: credentials minted while uploads are off are lost on the redeploy that is the only fix, while already stored on devices (Pocket NVS), and then 401 (NiBbLE review 3, N4). Local-only mode (`disabled`) is unaffected. Chat and beam traffic are not gated. Existing credentials keep working.

## 8. Request budget and accounting

`storage.py`: hand-rolled SigV4 over httpx (no boto3); `put/get/head/list/delete`; any object with those five methods can stand in (`set_client`, tests use `FakeR2` in `tests/conftest.py`).

- Class A = PUT/COPY/LIST/POST; class B = GET/HEAD; DELETE is free and uncounted. Free tier: 1M A, 10M B per month.
- Every call is counted in db table `r2_usage` (per UTC month) before the request, so a failed request still costs one. Budgets: `R2_CLASS_A_BUDGET` 800000, `R2_CLASS_B_BUDGET` 8000000.
- At a budget all R2 I/O stops (`Unavailable`), the app serves from local disk, new guests get 503, and it resumes next UTC month. Logged once per month per class.
- `accounting/usage.json` in R2 is merged back with `MAX` after a restore (`snapshot.load_usage`), so the counters survive a wipe. Usage is logged every 600 s.
- Cost per snapshot: 1 LIST (first flush only, then keys are tracked) + 1 PUT snapshot + 1 PUT pointer + 1 PUT usage (+ marker once) = about 3 class A. At the 30 s debounce under constant guest traffic that is up to ~8,600 class A/day, ~260k/month: inside 800k, but see Known gaps.
- Budget exhaustion stops uploads, so every redeploy that month restores an older snapshot. Treat a spent class A budget as an incident.

## 9. Transcripts

`transcripts.py`. Backend `TRANSCRIPT_BACKEND`: `auto` (default: `r2` if R2 configured, else `file`), `r2`, `file`.

- `r2`: entries buffer in memory; one object per flush per UTC day touched: `transcripts/YYYY-MM-DD/<hhmmss>-<id8>.jsonl` (one JSON entry per line). Not one per conversation: each `/chat` is its own session, so that would be one per turn.
- Flush triggers: timer every `TRANSCRIPT_FLUSH_S` (60, lazy: only while something is buffered), early at `TRANSCRIPT_BUFFER_MAX` (500 entries) or `TRANSCRIPT_BUFFER_BYTES` (4 MB), and on graceful shutdown. `main.py:58` runs `transcripts.stop()` before `snapshot.stop()` so the PUTs are counted in the final usage object.
- Request math: at most 60 class A per hour (one per flush per day touched), ~43k/month worst case, however many chats.
- Loss window: SIGTERM (Render redeploy) flushes first. SIGKILL, OOM, power loss: up to one flush interval (<= 60 s) of buffered entries.
- Failure: a failed PUT keeps entries buffered and retries. Budget spent: spill to `DATA_DIR/transcripts/YYYY-MM-DD.jsonl` at once. Buffer over cap while R2 is down: spill. Shutdown with R2 down: spill. The spill file is ephemeral on Render, so "never dropped silently" means logged ERROR, not guaranteed durable.
- Privacy: random per-conversation `session_id`, no user id, IP or handle.

## 10. Environment variables

R2 connection (secrets live in Render env / `.secrets`, never committed):

| Var | Default | Meaning |
|---|---|---|
| `R2_ENDPOINT` | unset | `https://<account id>.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | unset | S3-API token scoped to one bucket, Object Read & Write |
| `R2_BUCKET` | unset | dedicated bucket (`rabble-score`), never the firmware one |
| `R2_PREFIX` | `score/` | key prefix (a trailing `/` is added) |
| `R2_CLASS_A_BUDGET` / `R2_CLASS_B_BUDGET` | 800000 / 8000000 | monthly request budgets |

All four of endpoint, key id, secret, bucket must be set for R2 mode; otherwise local-only.

Snapshot behaviour:

| Var | Default | Meaning |
|---|---|---|
| `R2_ALLOW_FRESH_START` | unset | `1`/`true`/`yes` for ONE first boot; unset after |
| `SNAPSHOT_DEBOUNCE_S` | 30 | min dirty time before an upload |
| `SNAPSHOT_RESTORE_RETRY_S` | 300 | retry interval while state is `failed` |
| `SNAPSHOT_POINTER_RETRIES` | 3 | retries of the pointer's object before falling back |
| `SNAPSHOT_POINTER_RETRY_S` | 1 | sleep between those retries |
| `SNAPSHOT_KEEP` | 8 | newest N snapshots kept |
| `SNAPSHOT_KEEP_HOURLY_H` | 48 | hourly tier window, hours |
| `SNAPSHOT_KEEP_DAILY_D` | 90 | daily tier window, days |
| `SNAPSHOT_ALLOW_SHRINK` | unset | `1` allows a deliberate >10% drop in users/invites; unset after |
| `SNAPSHOT_ACCEPT_FALLBACK` | unset | restored key to accept after a fallback hold |

Transcripts: `TRANSCRIPT_BACKEND` (`auto`), `TRANSCRIPT_FLUSH_S` (60), `TRANSCRIPT_BUFFER_MAX` (500), `TRANSCRIPT_BUFFER_BYTES` (4194304). Also `DATA_DIR` (default `data`; the transcript spill defaults to `/tmp/rabble-data` if unset).

`server/env.defaults` is the in-repo copy of these; its R2 comment block predates generation-named snapshots (it still says `score-<UTC stamp>.db`). `render.reference.yaml` is stale: it still lists `TRANSCRIPT_BACKEND=file` and `CF_*` vars, and is not synced to the live service (env is set via `spells/render-ctl.sh`).

## 11. One worker, deploy overlap

- Run ONE uvicorn worker. The live start command is `uvicorn main:app --host 0.0.0.0 --port $PORT` (`server/Procfile`, `render.reference.yaml`): one process. `--workers N` would be N writers sharing one disk and one pointer.
- Render overlaps the old and new instance during a deploy. Both restore the same pointer; the old one's shutdown flush may move the pointer first. The new one's next pointer PUT then gets 412: fenced, re-merge (newer `updated_at` wins per row, consumed monotone), upload the union. Expect a fenced log line and one extra upload on a deploy with traffic.
- The fence only works if both sides run fenced code. The first deploy of this code may overlap an instance running older code that writes the pointer unconditionally and prunes by count (section 14).
- `stop()` may spend time on a re-merge (several R2 round trips). Render's SIGTERM grace period was not checked: a SIGKILL during it drops the fenced rows.

## 12. Recovery runbook

First: `GET /api/v1/admin/inventory` (admin key): `r2.snapshots` gives `state`, `hold`, `fallback_hold`, `baseline`, `latest`, `uploads_enabled`. Logs: `spells/render-ctl.sh logs`. Never delete `snapshots/INITIALIZED`, the pointer or any snapshot by reflex; list the bucket first.

- **Restore failed** (state `failed`, log "SNAPSHOT RESTORE FAILED"): the server serves a local db with uploads off and retries every 300 s. Read the logged reason: bad token or scope (fix `R2_*`), wrong `R2_BUCKET`/`R2_PREFIX` (fix env, do not set the fresh flag), budget spent, or genuinely no snapshot. Do not set `R2_ALLOW_FRESH_START` unless the bucket is verified empty by hand. Credential endpoints 503 meanwhile.
- **Hold, uploads refused** (`hold` = "local db has N users, last snapshot had M"): find out why the count dropped (stale disk, bad merge). If the shrink is real and intended, set `SNAPSHOT_ALLOW_SHRINK=1`, redeploy, then unset.
- **Fallback hold** (`fallback_hold` set): list `snapshots/` in R2. If the pointer's object is truly gone or corrupt, ack with `SNAPSHOT_ACCEPT_FALLBACK=<source key>` and redeploy. If it was a transient error, restart instead of acking and confirm a normal restore.
- **Fenced** (log "SNAPSHOT FENCED"): normal on a deploy overlap; it re-merges itself within one retry interval or at shutdown. If it repeats with no deploy, a second writer exists: a laptop with prod `R2_*`, a second worker, a stray service. Find and stop it.
- **R2 down** (errors, no 404): uploads fail and re-mark dirty; restore failures leave state `failed`. Wait; no action unless long. A redeploy during an outage cannot restore: avoid it.
- **Budget exhausted** (log "R2 class_a budget spent"): all R2 I/O stops till next UTC month, guest issue 503, transcripts spill to ephemeral disk. Do not redeploy. Raise the budget env only if still under R2's free tier; otherwise wait.
- **Wiped disk** (deploy or restart): expected; the boot restore handles it. If instead it comes up `failed` or on hold, see above. Data in R2 is intact until pruned; only the last <=30 s and unflushed transcripts are at risk.

## 13. First-deploy order

From `log/handoffs/HANDOFF-S339-Pocket-v0.1.1-sCoRE-Persistence.md` section 6 (all steps pending, none done):

1. Close the review items first (NiBbLE re-review of `snapshot.py`, `db.py`, `groqmeter.py`; CrumBbLE e2e). Then commit/cherry-pick sCoRE to `release/0.1.0`.
2. Mark creates an R2 S3-API token scoped to bucket `rabble-score` (Object Read & Write) and stores `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`.
3. Before pushing: set R2 env (`render-ctl env-set`) including `R2_ALLOW_FRESH_START=1` (first boot only), `TRANSCRIPT_BACKEND=r2` (or leave `auto`). Pushing wipes the ephemeral disk; with no export endpoint on prod yet, current accounts must be re-summoned. `GUEST_ISSUE_SECRET` and `R2_BUCKET` are already set on Render (effective at next deploy).
4. Push; confirm in logs "FRESH START" then "snapshot uploaded"; confirm `snapshots/INITIALIZED` and `latest.json` exist.
5. Unset `R2_ALLOW_FRESH_START`; deploy again; confirm the restore path ("restored database from R2 snapshot").
6. Deploy the Worker, real-board flash test, re-summon the Pocket (Mark's, then his dad's).
Step order 3 vs 2 in the handoff differs slightly (env set after push there); setting env before the push is the safer reading, unverified against how render-ctl applies it.

## 14. Known gaps

- **Unverified against real R2.** Tests use `FakeR2`. Nobody has run If-Match with a stale etag (expect 412), `If-None-Match: *` create-only, or the SigV4 client against the live bucket. Cloudflare documents conditional PutObject; the md5-etag assumption holds only for single-part, non-SSE-C objects (true here). Do one smoke test on a scratch bucket before deploy. Whether the June R2 token works for S3 API is unverified.
- **Guest counter writes trigger snapshots.** `guests.take_turn` (`guests.py:71-84`) writes with `track=True` (and even when it refuses), so guest traffic causes an upload about every 30 s, ~3 class A each. Size `SNAPSHOT_DEBOUNCE_S` and the budget against it; a spent budget freezes uploads for the month.
- **Old-code overlap on first deploy.** An instance running pre-fence snapshot code (if prod runs any: AGENT.md says nothing deployed, not checked) writes the pointer unconditionally and prunes by count; the fence holds only when both sides are fenced code.
- **Transcript spill is not durable** on Render (local file). Accepted best-effort under the loss window above; NiBbLE called a durable spool a blocker under Mark's invariant if transcripts count as data. Mark's ruling not recorded here.
- Retention trusts the wall clock (NiBbLE L-e). A missing-pointer "present" db does not scan for existing snapshot keys (L-c). Handle collisions across a merge (L2). A pass-4 test run once showed 4 transcript-test failures that did not reproduce in 3 reruns (unexplained, per CoBbLE fix 4 notes).
- Latest known suite (CoBbLE fix 4): 443 passed, 15 skipped. NiBbLE has not reviewed pass 4 as of this writing (review 3 covered pass 3; its N1-N4 are addressed by pass 4's `updated_at` merge, lineage check, self-fence adoption and the 503 gate, per CoBbLE notes, not independently re-verified).
- Not checked: Render SIGTERM grace, deploy overlap timing, prod `TRANSCRIPT_BACKEND`, worker count on the live service.

## Sources

`server/snapshot.py`, `db.py`, `storage.py`, `transcripts.py`, `auth_routes.py:98`, `users.py`, `migrations/0003_updated_at.sql`, `env.defaults`, `main.py:55-59`; `tests/test_snapshot.py`, `tests/test_snapshot_pass4.py`, `tests/test_transcripts.py`; `log/handoffs/HANDOFF-S339-Pocket-v0.1.1-sCoRE-Persistence.md`; crew notes `cobble-score-fix3/4.md`, `cobble-transcripts.md`, `nibble-review2/3.md` (ephemeral in `/tmp/rabble-crew/`).
