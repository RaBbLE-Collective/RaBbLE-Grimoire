# W3 spec: rabble_wifi_known (saved Wi-Fi networks)

> Clean-room spec, wave W3. Author role: S (Sonnet 5.5 sub-agent, S259). Firewall: S259 parent (Opus 5.5), approved after replacing the original's working-buffer sizes with a stack budget, dropping a caller's stack detail and a remark naming the original's log tag, and correcting the `wifi_channel` ownership (no current writer). The write order in 6.2 stays: the vectors observe it. Files to be replaced: `apache/rabble_wifi_known.c/.h`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen: the new Wi-Fi radio module (`w3-wifi.spec.md`, another author) calls them. Golden vectors: `w3-wifi-store-vectors/` (section 11).

Treatment: clean room. Everything below is a requirement. Where a number or a string is given it is a behaviour value; how you structure code, name helpers and split functions is yours.

---

## 1. Purpose

The device remembers up to eight Wi-Fi networks (name, password, and whether the network hides its name), most recently joined first. This module is the only code that reads or writes that list in flash. It offers load, remember (put one first), forget one, forget all, and wipe (clear passwords from a caller's copy). It does no Wi-Fi radio work and keeps no list in RAM between calls: every call reads the stored data afresh, so the stored data is the single truth.

The stored layout is a compatibility surface. Devices in the field already hold data in this layout; it must keep loading, and data this module writes must remain loadable by the layout rules below (and by code that only knows the legacy single-network keys).

## 2. Public interface (complete and frozen)

Header `rabble_wifi_known.h`, `#pragma once`, must include `<stdbool.h>`. `extern "C"` guards allowed.

| Name | Kind | Value / contract |
|---|---|---|
| `RABBLE_WIFI_KNOWN_MAX` | macro | `8` |
| `RABBLE_WIFI_KNOWN_SSID_MAX` | macro | `32` |
| `RABBLE_WIFI_KNOWN_PASS_MAX` | macro | `64` |
| `rabble_wifi_known_net_t` | struct (typedef) | in this order: `char ssid[RABBLE_WIFI_KNOWN_SSID_MAX + 1];` `char password[RABBLE_WIFI_KNOWN_PASS_MAX + 1];` `bool hidden;` (hidden = joined by name, does not show in scans) |
| `rabble_wifi_known_list_t` | struct (typedef) | in this order: `int count;` `rabble_wifi_known_net_t nets[RABBLE_WIFI_KNOWN_MAX];` Entries at index `count` and above are unspecified to callers but this module zero-fills them on load. |
| `void rabble_wifi_known_init(void)` | function | Prepare the module for concurrent use. Call once, after `nvs_flash_init()`, before any other call. Safe to call again (no effect the second time). |
| `int rabble_wifi_known_load(rabble_wifi_known_list_t *list)` | function | Fill `*list` from flash (section 5); return `list->count` (0 if nothing is saved). `list` is non-NULL. Never writes flash. |
| `bool rabble_wifi_known_remember(const char *ssid, const char *password, int hidden)` | function | Put the network first (section 7). `password` may be NULL (same as empty). `hidden`: 1 or any positive value sets the flag, 0 clears it, any negative value keeps the saved flag (false for a network not already saved). Returns true when the list was saved, false for an invalid argument or a failed save. |
| `bool rabble_wifi_known_forget(const char *ssid)` | function | Forget one network (section 8). Returns false only if saving failed. |
| `bool rabble_wifi_known_forget_all(void)` | function | Forget every network (section 9). Returns false only if erasing failed. |
| `void rabble_wifi_known_wipe(rabble_wifi_known_list_t *list)` | function | Overwrite the whole structure with zeros in a way the compiler cannot drop (secrets must not remain). `list` NULL is a no-op. |

Combined: 6 functions, 2 structs, 3 macros. No other symbol is exported.

### 2.1 Callers

Only the Wi-Fi radio module's keeper task calls this module (read from `rabble_wifi.c`; the radio itself is specified elsewhere):

| Call from the keeper | When |
|---|---|
| `rabble_wifi_known_init()` | once, from the radio module's start function. |
| `rabble_wifi_known_load(list)` | at start and after every change, to refresh the keeper's copy and the saved-networks view for the UI (ssid and hidden only). |
| `rabble_wifi_known_remember(ssid, pass, hidden)` with `hidden` 1 or 0 | the user joined a network from the settings page: `0` if the SSID was seen in the last scan, else `1` (typed names may be hidden). |
| `rabble_wifi_known_remember(ssid, pass, -1)` | after a successful join of a saved network that is not first: move it to the front, keeping its stored flag and password. |
| `rabble_wifi_known_forget(ssid)` / `rabble_wifi_known_forget_all()` | the user forgot one network, or all (empty name means all in the radio module; this module's `forget` itself treats an empty name as a no-op, section 8). |
| `rabble_wifi_known_wipe(list)` | after each use of a list that holds passwords. |

All calls come from one task today; the contract below must still hold for any task (section 10).

## 3. Storage layout

NVS namespace: `rabble_wifi`. All values are NVS strings (`nvs_set_str`/`nvs_get_str`), never blobs or integers. All keys below live in this namespace.

| Key | Content | Written by this module |
|---|---|---|
| `ssid` | the first network's name, 1 to 32 bytes | yes |
| `password` | the first network's password, 0 to 64 bytes; an open network stores an empty string (the key is present) | yes |
| `wifi_hidden` | the string `1` when the first network is hidden; the key is **absent** otherwise (a value of `0` is never written) | yes |
| `wifi_others` | JSON text for the networks after the first (section 4); the key is absent when there are no others | yes |
| `wifi_channel` | a legacy channel hint for the first network. No current RaBbLE code writes or reads it, but devices may hold one; this module never reads or writes it, only erases it | **erased only** (section 7.3, 9) |

The first network lives in `ssid`/`password` so that code which knows only one network still finds it. A name or password is a byte string (not necessarily UTF-8); lengths are in bytes; comparison of names is exact bytes, case-sensitive.

Other keys that may exist in the namespace are left alone.

### 3.1 Empty or missing namespace

If the namespace does not exist (never written) or cannot be opened, every read behaves as if the key were absent. Load returns 0. A write creates the namespace.

## 4. The `wifi_others` JSON

Written compactly with no whitespace: an array of objects, one per network after the first, in list order (most recent first).

Each object has the fields, in this order: `"s"` (string, the SSID), `"p"` (string, the password, present even when empty), and `"h":true` only when the network is hidden (never `"h":false`, never any other value). Example with two others, the second hidden:

`[{"s":"Cafe","p":"latte"},{"s":"Home","p":"","h":true}]`

String escaping when writing: `"` as `\"`, backslash as `\\`, backspace, form feed, newline, carriage return, tab as `\b \f \n \r \t`, any other byte below 0x20 as `\u00xx` with four lowercase hex digits (`\u0001`), the byte 0x7f, every byte of 0x80 and above, and `/` are written raw (unescaped). Non-UTF-8 bytes are written raw.

Byte-exact examples are in the vectors (`json_plain`, `json_escapes`).

### 4.1 Size limit

The JSON text (without terminator) must be shorter than 1536 bytes, i.e. at most 1535 characters, so that its stored value (with terminator) fits the 1536-byte read capacity of section 5. If the text for the networks after the first would be 1536 bytes or longer, the **oldest** network (the last in the list) is dropped from what is saved, the text is rebuilt, and this repeats until it fits or only the first network remains (then no `wifi_others` key is stored). Dropping logs, once per dropped network, at warning level: `saved networks too long; forgetting <ssid>`. Eight networks normally fit with room to spare; the limit bites only with names and passwords full of characters that escape to six bytes (control bytes). The first network is never dropped by this rule. A save that dropped networks this way still returns true, provided the writes themselves succeeded.

## 5. Load: how stored data is read

Load is a pure read and must accept everything a device in the field might hold, including data left by older firmware, hand-edited values and damage. It builds the list in this order and applies the **acceptance rule** (5.3) to each candidate.

### 5.1 The first network (legacy keys)

1. Read `ssid`. If the key is absent, or longer than 32 bytes (it cannot be read into the 33-byte field), or empty, there is no first network from these keys: `password`, `wifi_hidden` and `wifi_channel` are ignored.
2. Otherwise read `password`: if absent, or longer than 64 bytes, the password is the empty string.
3. `hidden` is true only when `wifi_hidden` is present and its value is exactly the one-character string `1` (`0`, `11`, empty, `true`, `2` are all not hidden).
4. The candidate goes through the acceptance rule.

### 5.2 The other networks

1. Read `wifi_others` with a capacity of 1536 bytes including terminator. If the key is absent, or the value is 1536 characters or longer (it cannot be read), it is ignored silently (no warning).
2. Parse the text as JSON using ordinary JSON rules, including: leading whitespace allowed; text after the first complete value is ignored (`[...]xyz` is accepted); string escapes decoded (`\" \\ \/ \b \f \n \r \t`, `\uXXXX` to UTF-8, surrogate pairs combined). A decoded string ends at its first NUL (`\u0000` truncates the string; an SSID that becomes empty is rejected by the acceptance rule).
3. If the text is non-empty and either fails to parse or parses to something other than an array, log at warning level `ignoring unreadable saved networks` and treat there as no others. An empty text or an empty array is silent.
4. For each element of the array, in order: skip anything that is not an object. The element's `s` must be a string, else skip. `p` is used if it is a string, else the password is the empty string. `hidden` is true only when `h` is the JSON literal `true` (the number 1, the string `"true"`, `false`, `null`, anything else is not hidden). Field names are case-sensitive (`S`, `P`, `H` mean nothing). If an object repeats a field name, the first occurrence counts; unknown fields are ignored. Each candidate goes through the acceptance rule.

### 5.3 Acceptance rule (applies to the first network and to every element)

A candidate is added at the end of the list unless any of these hold, in which case it is silently skipped and the scan continues:

- the list already has `RABBLE_WIFI_KNOWN_MAX` (8) entries (so at most 8 are kept; later ones are ignored, first and then array order);
- the SSID is empty or longer than 32 bytes;
- the password is longer than 64 bytes;
- an entry with exactly the same SSID is already in the list (the earlier entry wins, with its own password and hidden flag; case differences make names distinct).

Stored entries are never repaired during load; the next save rewrites a cleaned list (section 7.4).

Notes on consequences (all pinned by vectors): with the `ssid` key unusable, the first valid element of `wifi_others` becomes the list's first network, and the next save promotes it into the legacy keys. An `ssid` stored as the empty string is as good as absent.

### 5.4 Result

`list->count` is the number of accepted entries; the struct is zero-filled before loading. Return value equals count. If working memory for the `wifi_others` text cannot be obtained, log at warning level `no memory for the other saved networks` and return what was loaded from the legacy keys (the first network only).

## 6. The saving rule (shared by remember, forget, forget-all)

Every change builds a complete new desired list (ordered, at most 8, passing the acceptance rule) and writes it out as below. There is no partial update of a single key to reflect a single field.

### 6.1 Empty desired list

Erase `ssid`, `password`, `wifi_hidden`, `wifi_others` and `wifi_channel`, in this order. A key that is not there is not an error. Each erase is committed. Other keys are untouched.

### 6.2 Non-empty desired list

Perform these steps in this order. Let F be the desired first network.

1. `ssid`: write F's name unless the stored value is already identical. (A stored value that is absent, or too long to read back, counts as different.) Remember whether the value changed.
2. `wifi_channel`: if step 1 changed the stored name, erase `wifi_channel` now. (The channel hint belonged to the previous first network.) If the name did not change the key is left alone, even if the password or hidden flag changes.
3. `password`: write F's password unless identical. An empty password is written as an empty string, so the key exists.
4. `wifi_hidden`: if F is hidden, write `1` unless identical; otherwise erase the key.
5. `wifi_others`: if the desired list has more than one entry, write the JSON of section 4 (after applying the 4.1 size rule) unless identical; otherwise erase the key.

Rules that apply to all steps:

- **Skip identical writes.** A write whose value equals what is stored must not be issued (flash wear). The vectors' `writes` column pins this.
- **Per-key commit.** Each key write or erase is committed on its own. There is no multi-key atomicity.
- **Keep going.** If one step fails, the later steps are still attempted. The save returns false if any step failed. No rollback is attempted. A partial save is possible (for example the new `ssid` with the old `wifi_others`) and must still load as a valid list under section 5; the step order above is chosen so that at every point a valid first network is stored (name then password) and a failure never leaves the namespace unreadable.
- A failure to open the namespace for writing fails every step.
- On a failed save log at warning level: `saving the Wi-Fi networks failed`.

## 7. remember

`rabble_wifi_known_remember(ssid, password, hidden)`:

1. **Validation, before any flash access.** Return false, with no read, no write and no log, if `ssid` is NULL or empty, longer than 32 bytes, or `password` (NULL counts as empty) is longer than 64 bytes.
2. Load the current list (section 5). Its normalisation applies: malformed or over-limit stored entries are not carried over.
3. The desired list is: the new network first, then every entry of the loaded list except one with the same SSID, in their existing order, kept while the list has fewer than 8 entries. The oldest entries beyond 8 are dropped. The new network's password is always the supplied one (an existing network's password is replaced).
4. The new network's hidden flag: `hidden` positive: true. `hidden` zero: false. `hidden` negative: the flag the same SSID had in the loaded list, or false if it was not in the list.
5. Save per section 6. Return whether the save succeeded.

### 7.1 Ordering and eviction examples

Remembering a network already in the list moves it to the front without evicting anyone (the list does not grow). Remembering a new ninth network drops the oldest. Remembering the current first network again with unchanged data writes nothing (vectors `rem_same_first_idempotent`).

### 7.2 Hidden flag, tri-state summary

| Argument | Network already saved | Network not saved |
|---|---|---|
| 1 (or any positive) | hidden | hidden |
| 0 | not hidden | not hidden |
| negative | keeps its saved flag | not hidden |

### 7.3 Channel hint

`wifi_channel` is erased exactly when the first network's name changes in a save (including the case where the `ssid` key was absent or unreadable before), and by forget-all or when the list ends up empty. It survives a save that keeps the same first network, whatever else changes, and it survives forgetting a network that is not first. Load never touches it.

### 7.4 Normalising effect

Because every save writes the whole desired list from a freshly loaded one, saving cleans the store: duplicates collapse, entries that fail acceptance disappear, entries beyond eight go, a stale `wifi_hidden` for a non-hidden first network is erased, `wifi_others` that was unreadable is erased or replaced, and a first network that came only from `wifi_others` moves into `ssid`/`password`. This happens even in `forget` of a network that is not saved (section 8).

## 8. forget

`rabble_wifi_known_forget(ssid)`:

1. If `ssid` is NULL or empty, return true at once: no read, no write.
2. Load the current list. Remove the entry whose SSID matches exactly (case-sensitive; a name longer than 32 bytes matches nothing). The remaining entries keep their order and data.
3. Save the result per section 6, **even if nothing matched** (this is the normalising rewrite of 7.4; if the data was already clean it writes nothing).
4. Return false only if the save failed; true when the name was not found.

If the removed entry was first, the next entry takes its place: its name goes to `ssid`, its password to `password`, `wifi_hidden` is written or erased to match it, `wifi_others` is rewritten (or erased if it was the last one remaining after promotion), and `wifi_channel` is erased because the first name changed. Forgetting the only network empties everything as in 6.1.

## 9. forget-all

`rabble_wifi_known_forget_all()`: save the empty list per 6.1, regardless of what is stored (including malformed data and a stray `wifi_channel`). Returns false only if an erase failed; the other erases are still attempted. It does not first read the stored data for its result (a warning for unreadable stored data may still be logged by an implementation that does).

## 10. Concurrency, memory and stack

- **Thread-safe from any task.** Concurrent calls from different tasks (load, remember, forget, forget-all) must each see and leave a consistent store: a call's read-modify-write must not interleave with another call's. `rabble_wifi_known_init` establishes whatever is needed; calls made before `init` still work (single-task use) but are not serialised.
- **Internal-RAM-stack constraint.** These calls read and write NVS (flash). Flash writes suspend the cache, so the calling task must have its stack in internal RAM (created with the plain FreeRTOS task-create call, not a PSRAM-stack variant). The new header must carry a comment saying so. The module itself must keep its own stack use under 512 bytes per call (excluding ESP-IDF's NVS internals): working lists and JSON text come from the heap, not the caller's stack. Callers may have stacks as small as 6 KB.
- **Allocation failure.** A call that cannot get working memory fails safely: `load` per 5.4; `remember`, `forget` and `forget-all` return false, log at warning level `no memory to update the saved networks`, and change nothing in flash.
- **Secrets hygiene.** Temporary copies of passwords (the loaded lists, JSON text, parse trees, scratch buffers used to compare stored values) are cleared with a non-elidable overwrite before they are freed. The caller is responsible for `rabble_wifi_known_wipe` on its own list.

## 11. Test vehicle and golden vectors

The logic is pure given an NVS, so it is fully host-testable. The implementer builds a **host test vehicle** that links the store against an in-memory NVS with these semantics, and replays `w3-wifi-store-vectors/scenarios.txt`, comparing to `store.tsv` as `README.md` there explains.

In-memory NVS semantics the store must run against (these are the real NVS behaviours the store depends on):

| Call | Behaviour |
|---|---|
| open the namespace read-only | fails (not found) until something has been written or seeded in it; opening read-write creates it |
| string read into a buffer of capacity N | fails if the key is absent; fails (invalid length) if the stored string with its terminator needs more than N bytes, in which case nothing is copied; otherwise copies it |
| string write | stores the value (any length up to a few KB); failure injection per key |
| erase key | success if the key existed; "not found" if it did not (the store must treat this as success); failure injection per key |
| commit | success |

The vectors cover 134 scenarios and 239 rows: legacy and malformed contents loading, every JSON edge listed in section 5, remember ordering and eviction, tri-state hidden, channel erasure, forget including promotion, forget-all, normalising rewrites, JSON byte exactness including escapes, the size limit with eviction, and injected write, erase and open failures (with the resulting partial store and return value). All rows must pass exactly on `ret`, `writes` (sequence), `nvs_after` and `load_after`. Compare `logs` only if the vehicle captures log output.

The vectors also cover wipe indirectly only in that it is not tested; test wipe separately (fill a list, wipe, check every byte zero, check NULL is accepted).

## 12. Device behaviour checklist (integrator)

Log text references are exact. The store has no serial command of its own; on the device it is exercised through the radio module's join and forget paths and read back from the NVS partition.

### 12.1 Serial-only

1. Boot with a device that already has data from the previous firmware (the integrator should keep a flash image from before the swap): the saved networks list in the settings UI and the log show the same networks, in the same order, with the same hidden flags, and the device joins as before. No `ignoring unreadable saved networks` warning.
2. Join a new network through the radio path: reading the namespace back (esptool/NVS dump, or the host-side NVS parse of a flash read) shows `ssid`, `password`, no `wifi_hidden` (picked from a scan) or `wifi_hidden`=`1` (typed), and `wifi_others` as the previous first network, byte-exact per section 4.
3. Forget the first network while others exist: the next one is in `ssid`/`password`, `wifi_channel` is gone, `wifi_others` shrinks or goes away. Forget all: all five keys are gone.
4. Join a saved network that is not first (let the radio rejoin it): it moves first with its flag and password kept (negative-hidden path), and only changed keys are written (flash write count does not rise for unchanged keys, if measurable).
5. Power-cycle between steps 2 and 4: the list reloads identically.
6. No stack overflow or watchdog in any step (a flash write while the display is animating must not hang: the calling task has an internal stack).

### 12.2 Needs Mark's hands

1. In the settings Wi-Fi page, remember eight networks, then a ninth: the oldest is gone, the other eight are in order.
2. A hidden network joined by typed name survives a reboot and rejoins.
3. Pull power during a save (hard to time; optional): after the reboot the device still has a valid first network.

---

## 13. Ambiguities and decisions for the integrator

1. **Forget of an unknown or malformed-data name rewrites the store.** `forget("zzz")` on dirty data normalises it (and writes nothing on clean data). The radio module may rely on neither; kept so a user's "forget" cleans a damaged store.
2. **`forget("")` is a no-op returning true; `forget_all` is the way to clear.** The radio module maps an empty name to `forget_all`.
3. **Failed writes are not rolled back.** After a partial failure the first network can carry a new name and an old password, or the reverse. Order was kept so the new name goes first and the password right after; a power cut between the two leaves the new name with the old password, which fails to join until the user re-enters it. Kept as is.
4. **A stored `ssid` longer than 32 bytes is dropped silently,** as is any `wifi_others` of 1536 characters or more. The first loses that network, the second loses all others, until the next save rewrites them. Kept as recorded.
5. **`wifi_channel` is a legacy key.** This store only erases it. If a later radio module writes a channel hint there, it must not assume it survives a change of first network.
6. **Interface comment on the stack constraint** (section 10) is a requirement on the new header text, not just the behaviour.
7. **Log texts** other than the warning strings quoted in this spec are free to differ; the log tag name is free.
8. **Nothing in the interface reports "which network was dropped"** by the size limit or the 8-entry cap; the caller can only see it by loading again. Left as is.
