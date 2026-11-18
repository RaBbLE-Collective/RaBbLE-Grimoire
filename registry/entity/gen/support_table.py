#!/usr/bin/env python3
"""Generate RaBbLE-NeBuLA-Effects-Support.md from registry/entity/rabble.entity.json.

Run: RaBbLE-Grimoire/registry/entity/.venv/bin/python RaBbLE-Grimoire/registry/entity/gen/support_table.py
Output is deterministic: ids and groups are sorted, no timestamps.
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
ENTITY_DIR = HERE.parent
GRIMOIRE = ENTITY_DIR.parent.parent
SOURCE = ENTITY_DIR / "rabble.entity.json"
OUT = GRIMOIRE / "RaBbLE-NeBuLA" / "RaBbLE-NeBuLA-Effects-Support.md"
SURFACES = ["web", "web3d", "ball", "pocket_web", "pocket_hw", "terminal", "studio"]
MOVES = ["turn", "portal_swap", "blink", "withdraw"]
REGEN = "RaBbLE-Grimoire/registry/entity/.venv/bin/python RaBbLE-Grimoire/registry/entity/gen/support_table.py"


def cell(text):
    return str(text).replace("|", "\\|")


def row(values):
    return "| " + " | ".join(cell(v) for v in values) + " |"


def main():
    reg = json.loads(SOURCE.read_text(encoding="utf-8"))
    effects = reg["base"]["effects"]
    moves = reg["base"]["moves"]

    groups = {}
    for eid, eff in effects.items():
        groups.setdefault(eff["group"], []).append(eid)

    lines = []
    lines.append("# NeBuLA Effects Support Table")
    lines.append("")
    lines.append("> Generated file. Do not edit by hand.")
    lines.append(f"> Source: `RaBbLE-Grimoire/registry/entity/rabble.entity.json` (registry version {reg['version']}).")
    lines.append(f"> Regenerate: `{REGEN}`")
    lines.append("")
    lines.append("Per-effect, per-surface support taken from the entity registry. Contract: `RaBbLE-Grimoire/registry/entity/RaBbLE-Entity-Registry-Schema.md`.")
    lines.append("")
    lines.append("## Legend")
    lines.append("")
    lines.append("- **full**: the effect runs with its base parameters on that surface.")
    lines.append("- **reduced**: the same idea at a lower cost, using the effect's `reduced` overrides.")
    lines.append("- **none**: skipped on that surface without error.")
    lines.append("- **Priority**: 0 = defining (never yields, eyes and portals), 1 = key expression, 2 = expressive, 3 = ambient, 4 = decor. Lower numbers yield last; priority 0 never yields.")
    lines.append("- **Cost tier**: trivial, low, medium or high (registry estimate; device cost is filled only from measurement).")
    lines.append("")

    for group in sorted(groups):
        lines.append(f"## Group: {group}")
        lines.append("")
        lines.append(row(["Effect id", "Label", "Priority", "Cost tier"] + SURFACES))
        lines.append(row(["---"] * (4 + len(SURFACES))))
        for eid in sorted(groups[group]):
            eff = effects[eid]
            support = eff["support"]
            lines.append(row([
                f"`{eid}`",
                eff["label"],
                eff["priority"],
                eff["cost"]["tier"],
            ] + [support[s] for s in SURFACES]))
        lines.append("")

    lines.append("## Moves")
    lines.append("")
    lines.append(row(["Move", "Duration (s)"] + SURFACES))
    lines.append(row(["---"] * (2 + len(SURFACES))))
    for mid in MOVES:
        mv = moves[mid]
        sup = mv["params"]["support"]
        lines.append(row([f"`{mid}`", mv["duration"]] + [sup[s] for s in SURFACES]))
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT}")
    print(f"groups={len(groups)} effects={len(effects)} moves={len(MOVES)}")


if __name__ == "__main__":
    main()
