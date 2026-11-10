# gist/ — Distilled Grimoire

High-density, low-token summaries of canonical Grimoire docs. Each gist is ~250-320 words.

**To get the full picture in minimal tokens:**
```bash
cat gist/*.md        # ~5,000 tokens total (measured S322, bytes / 4) — complete orientation
```

**To regenerate after docs change:**
```bash
bash spells/distill-gists.sh          # all, or pass a slug (roadmap, episode1, …)
```

Gists are distilled, not canonical. The source doc is always authoritative: fix the source first,
then regenerate (or hand-sync the gist and note it in its header, as S248 did).
The pre-commit hook warns when a source is newer than its gist.

---

## Index

Token counts ≈ words × 1.35 (measured S248).

| Gist | Source | Gist Tokens | Source Tokens |
|---|---|---|---|
| `RaBbLE-Identity-gist.md` | `RaBbLE-Agent/RaBbLE-Identity.md` | ~310 | ~2,900 |
| `RaBbLE-Collective-gist.md` | `RaBbLE-Agent/RaBbLE-Collective.md` | ~450 | ~2,100 |
| `RaBbLE-Roadmap-gist.md` | `RaBbLE-Agent/RaBbLE-Roadmap.md` | ~360 | ~1,700 |
| `RaBbLE-CommitStyle-gist.md` | `RaBbLE-Agent/RaBbLE-CommitStyle.md` | ~350 | ~630 |
| `RaBbLE-Versioning-gist.md` | `RaBbLE-Versioning.md` | ~350 | ~1,600 |
| `RaBbLE-Palette-gist.md` | `RaBbLE-Agent/RaBbLE-Palette.md` | ~290 | ~1,200 |
| `RaBbLE-Episode1-gist.md` | `log/EP1-AIR-CHECKLIST.md` | ~340 | ~1,500 |
| `RaBbLE-Integration-Map-gist.md` | `RaBbLE-Agent/RaBbLE-Integration-Map.md` | ~350 | ~1,100 |
| `RaBbLE-Entity-gist.md` | `log/plans/Unified-Entity/Unified-Entity-Canon.md` (hand-written) | ~330 | ~1,500 |

`RaBbLE-Episode1-gist.md`, and the Episode sections of the Roadmap and Versioning gists, describe a model that is retiring (S318 D3). They stay until the replacement is ruled; sCoRE's chat persona loads Identity, Collective, Episode1 and Roadmap by filename (`RaBbLE-sCoRE/server/grimoire.py`), so do not rename a gist without changing that list.

`gist/index.html` is the browsable Grimoire page (not read by `cat gist/*.md`).
