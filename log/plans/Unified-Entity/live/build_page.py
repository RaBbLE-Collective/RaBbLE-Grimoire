#!/usr/bin/env python3
"""Build the Aether page for the unified entity spec: the markdown and the role-frame poses are embedded as data,
so re-running this after a spec edit keeps the page identical to the spec.

usage: build_page.py SPEC_MD POSES_JSON TEMPLATE_HTML OUT_HTML
"""
import json, sys

spec, poses, tpl, out = sys.argv[1:5]
md = open(spec, encoding="utf-8").read()
data = json.load(open(poses))
html = open(tpl, encoding="utf-8").read()
# </script> inside embedded data would close the tag: escape the slash
blob = lambda o: json.dumps(o).replace("</", "<\\/")
live = open(__file__.rsplit("/",1)[0] + "/live.js", encoding="utf-8").read().rstrip()
assert live.endswith("})();"); live = live[:-5]
html = html.replace("/*__LIVE__*/", live)
html = html.replace("/*__SPEC__*/null", blob(md)).replace("/*__POSES__*/null", blob(data))
open(out, "w", encoding="utf-8").write(html)
print(f"wrote {out} ({len(html)} bytes)")
