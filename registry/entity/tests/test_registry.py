"""Pass fixture = the real registry. Failing fixtures are mutation files applied to it in memory
(tests/fixtures/*.json: check, description, ops). Each must fail with its own check code."""
import copy, json, subprocess, sys
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
import validate  # noqa: E402

REAL = (ROOT / "rabble.entity.json").read_text()
FIXTURES = sorted((ROOT / "tests" / "fixtures").glob("*.json"))


def resolve(node, step):
    if isinstance(step, dict):
        (k, v), = step.items()
        return next(i for i, x in enumerate(node) if x[k] == v)
    return step


def apply(text, fx):
    data = json.loads(text)
    indent = 2
    for op in fx["ops"]:
        if op.get("serialize") == "indent4":
            indent = 4; continue
        node = data
        path = op["path"]
        for step in path[:-1]:
            node = node[resolve(node, step)]
        last = resolve(node, path[-1])
        if "set" in op: node[last] = op["set"]
        else: del node[last]
    return json.dumps(data, indent=indent, sort_keys=True, ensure_ascii=False) + "\n"


def test_real_registry_passes():
    r = validate.validate_text(REAL)
    assert r.errors == []


def test_real_registry_v11_is_a_warning():
    r = validate.validate_text(REAL)
    assert any(c == "V11" for c, _ in r.warnings)


def test_cli_exit_codes(tmp_path):
    py = sys.executable
    assert subprocess.run([py, str(ROOT / "validate.py")], capture_output=True).returncode == 0
    bad = tmp_path / "bad.json"
    bad.write_text(apply(REAL, json.loads((ROOT / "tests/fixtures/v05_no_touch.json").read_text())))
    assert subprocess.run([py, str(ROOT / "validate.py"), str(bad)], capture_output=True).returncode == 1


def test_one_fixture_per_check():
    have = {json.loads(f.read_text())["check"] for f in FIXTURES}
    assert have == {f"V{i}" for i in range(1, 13)} | {"V6b"}


@pytest.mark.parametrize("path", FIXTURES, ids=[f.stem for f in FIXTURES])
def test_failing_fixture(path):
    fx = json.loads(path.read_text())
    r = validate.validate_text(apply(REAL, fx))
    assert r.errors, f"{path.stem} produced no error"
    assert fx["check"] in r.codes(), f"{path.stem}: expected {fx['check']}, got {sorted(r.codes())}: {r.errors[:3]}"
