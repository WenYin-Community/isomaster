#!/usr/bin/env python3
"""Dump the AT-SPI accessibility tree of the ISO Master window.
Usage: a11y_dump.py [--lists-only]
"""
import sys
import pyatspi

lists_only = "--lists-only" in sys.argv

desktop = pyatspi.Registry.getDesktop(0)


def dump(node, depth=0, maxdepth=14):
    if depth > maxdepth:
        return
    try:
        n = node.childCount
    except Exception:
        return
    for i in range(n):
        try:
            c = node[i]
            role = c.getRoleName()
            name = c.name or ""
            if lists_only:
                if role in ("list item", "table cell", "list", "label"):
                    print("  " * depth + f"[{role}] {name[:70]}")
            else:
                if role in ("list item", "table cell", "list", "label",
                            "push button", "text", "frame", "application") or name:
                    print("  " * depth + f"[{role}] {name[:70]}")
        except Exception:
            continue
        dump(c, depth + 1, maxdepth)


found = False
for app in desktop:
    try:
        if "isomaster" in (app.name or "").lower():
            found = True
            dump(app)
            break
    except Exception:
        continue

if not found:
    print("isomaster application not found")
    sys.exit(1)
