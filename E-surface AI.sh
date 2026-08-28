#!/usr/bin/env bash
set -euo pipefail

# Bhagavad Gita — selected ślokas from your notebook
# Cheiro / Chaldean calculation:
# 1=AIJQY, 2=BKR, 3=CGLS, 4=DMT, 5=EHNX,
# 6=UVW, 7=OZ, 8=FP, 9=no letters.

python3 - <<'PY'
import csv
import json
import sys
import time
import unicodedata
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

REFS = ['1.28', '2.2', '2.3', '2.12', '2.13', '2.15', '2.16', '2.17', '2.23', '2.25', '2.44', '2.48', '2.56', '3.5', '3.8', '4.1', '4.2', '4.5', '4.6', '4.7', '4.8', '4.13', '4.14', '8.3', '8.4', '8.5', '8.6', '8.8', '8.9', '8.11', '8.13', '8.14', '9.1', '9.5', '9.6', '9.8', '9.9', '9.10', '9.17', '9.18', '9.30', '10.3', '10.4', '10.5', '10.21', '10.22', '10.23', '10.24', '10.25', '10.26', '10.27', '10.28', '10.29', '10.30', '10.31', '10.32', '10.33', '10.34', '10.35', '10.36', '10.37', '10.38', '10.39', '10.40', '10.41', '11.8', '11.10', '11.11', '11.18', '11.20', '12.2', '12.3', '12.5', '12.9', '12.10', '12.11', '12.12', '12.13', '12.14', '13.6', '13.7', '13.8', '13.9', '13.10', '13.11', '13.12', '13.14', '13.15', '13.16', '13.17', '13.18', '13.24', '13.27', '13.31', '13.33', '14.1', '14.3', '14.4', '14.5', '14.6', '14.7', '14.8', '14.9', '14.10', '14.11', '14.12', '14.13', '14.16', '14.17', '14.19', '14.20', '14.22', '14.23', '14.24', '14.25', '15.1', '15.2', '15.3', '15.4', '15.6', '15.7', '15.9', '15.10', '15.11', '15.12', '15.13', '15.14', '15.15', '16.1', '16.2', '16.3', '16.4', '16.7', '16.9', '16.10', '16.11', '16.12', '16.13', '16.14', '16.15', '16.20', '16.21', '16.22', '17.2', '17.3', '17.8', '17.9', '17.10', '17.11', '17.12', '17.13', '17.16', '17.17', '17.23', '17.24', '18.2', '18.4', '18.5', '18.6', '18.7', '18.8', '18.9', '18.14', '18.17', '18.18', '18.19', '18.20', '18.21', '18.22', '18.23', '18.24', '18.25', '18.26', '18.27', '18.28', '18.37', '18.38', '18.39', '18.40', '18.42', '18.43', '18.44', '18.59']

VALUES = {
    "a":1,"i":1,"j":1,"q":1,"y":1,
    "b":2,"k":2,"r":2,
    "c":3,"g":3,"l":3,"s":3,
    "d":4,"m":4,"t":4,
    "e":5,"h":5,"n":5,"x":5,
    "u":6,"v":6,"w":6,
    "o":7,"z":7,
    "f":8,"p":8
}

API = "https://gita.ekrasworks.com/api/v1/verse/{}/{}"

def normalize(s):
    s = unicodedata.normalize("NFD", s)
    s = "".join(ch for ch in s if unicodedata.category(ch) != "Mn")
    return "".join(ch for ch in s.lower() if "a" <= ch <= "z")

def root(n):
    while n > 9:
        n = sum(int(x) for x in str(n))
    return n

def fetch(ref):
    ch, verse = map(int, ref.split("."))
    req = Request(API.format(ch, verse), headers={"User-Agent": "Gita-Cheiro-Analyzer/1.0"})
    with urlopen(req, timeout=20) as response:
        return json.load(response)

rows = []

print()
print("BHAGAVAD GITA - CHEIRO / CHALDEAN ANALYSIS")
print("Selected verses:", len(REFS))
print()

for ref in REFS:
    try:
        data = fetch(ref)
        m = data.get("mula") or data.get("mūla") or {}
        iast = m.get("iast") or m.get("transliteration")
        dev = m.get("devanagari") or m.get("sanskrit") or m.get("sanskrit_devanagari")

        if not iast:
            raise ValueError("IAST field not found in API response.")

        norm = normalize(iast)
        total = sum(VALUES[ch] for ch in norm)
        r = root(total)

        rows.append({
            "Verse": ref,
            "Devanagari": dev or "",
            "IAST": iast,
            "Normalized": norm,
            "Compound": total,
            "Root": r
        })

        print("=" * 78)
        print("BG", ref)
        if dev:
            print(dev)
        print("IAST:", iast)
        print("Normalized:", norm)
        print(f"Compound: {total}    Root: {r}")
        print()

        time.sleep(0.05)

    except (HTTPError, URLError, TimeoutError, ValueError, KeyError) as exc:
        print(f"FAILED {ref}: {exc}", file=sys.stderr)

with open("gita_cheiro_results.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=["Verse", "Devanagari", "IAST", "Normalized", "Compound", "Root"]
    )
    writer.writeheader()
    writer.writerows(rows)

print("=" * 78)
print(f"Fetched successfully: {len(rows)} / {len(REFS)}")
print("Saved: gita_cheiro_results.csv")
print("Source API: https://gita.ekrasworks.com/api/v1/verse/{chapter}/{verse}")
PY
