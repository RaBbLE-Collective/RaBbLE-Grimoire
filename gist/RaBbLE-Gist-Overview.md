# gist/ — Distilled Grimoire

`cat gist/*.md` is the orientation read: about 4,000 tokens (measured S322, bytes / 4). Gists are distilled, not canonical: fix the source first, then `bash spells/distill-gists.sh [slug]` or hand-sync and say so in the gist header. The pre-commit hook warns when a source is newer than its gist.

Gists: Identity, Entity (hand-written), Collective, Roadmap, Versioning, Palette, CommitStyle, Integration-Map. Each header names its source. sCoRE's chat persona loads Identity, Collective, Entity and Roadmap by filename (`RaBbLE-sCoRE/server/grimoire.py`): rename one only together with that list.
