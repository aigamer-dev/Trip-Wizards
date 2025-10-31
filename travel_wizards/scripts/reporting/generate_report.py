#!/usr/bin/env python3
"""
Aggregate test outputs (Puppeteer JSON + Flutter JSON) into the required Markdown report template.
Usage:
  python3 scripts/reporting/generate_report.py --dir artifacts/ --out report.md
"""
import argparse
import json
import os

TEMPLATE_HEADER = '''# Application Interactive Feature Test Report

## ⚠️ Travel Wizards Interactive Feature Test Report

| Feature Category | Test Case | Platform | Status (PASS/FAIL) | Details/Observed Issue |
| :--- | :--- | :--- | :--- | :--- |
'''


def load_json_files(dirpath):
    results = []
    if not os.path.isdir(dirpath):
        return results
    for fn in os.listdir(dirpath):
        if fn.endswith('.json'):
            try:
                data = json.load(open(os.path.join(dirpath, fn)))
                results.append((fn, data))
            except Exception as e:
                results.append((fn, {'error': str(e)}))
    return results


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--dir', '-d', default='artifacts')
    p.add_argument('--out', '-o', default='artifacts/report.md')
    args = p.parse_args()

    rows = []
    files = load_json_files(args.dir)
    for fn, data in files:
        # probe shape
        if isinstance(data, dict) and 'results' in data:
            for r in data['results']:
                rows.append((r.get('test','unknown'), r.get('status','ERROR'), r.get('output','')))
        else:
            rows.append((fn, 'UNKNOWN', json.dumps(data)[:200]))

    # Build a simple report mapping
    md = TEMPLATE_HEADER
    for test, status, details in rows:
        md += f"| {test} | {test} | Mixed | {status} | {details} |\n"

    # Append TODO section
    md += "\n### ❌ List of Incomplete/Not Working Features (Summary)\n\n"
    md += "TODO Tasks\n----------\n\n- [ ] Add all the tasks that need to be fixed/updated based on the test results as TODO lists.\n"

    outdir = os.path.dirname(args.out)
    if outdir and not os.path.exists(outdir):
        os.makedirs(outdir)
    with open(args.out, 'w') as f:
        f.write(md)
    print('Wrote report to', args.out)

if __name__ == '__main__':
    main()
