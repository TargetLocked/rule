import json
import pathlib
import sys

rules = []
for path in sys.argv[1:]:
    path = pathlib.Path(path)
    if path.exists():
        with open(path, "r") as f:
            src = json.load(f)
        rules.extend(src["rules"])
print(json.dumps({"version": 1, "rules": rules}))
