#!/usr/bin/env python3
"""
Correlate windowed artefacts against ground-truth actions for one scenario.

Reads (all under <scenario_root>/artefacts/analysis/windowed/):
  windows.csv                             per-action start/end
  *prefetch*_windowed.csv                 Zimmerman PECmd Timeline, filtered
  events_windowed.csv                     EvtxECmd, filtered
  NTUSER.csv, UsrClass.csv                SBECmd (not window-filtered upstream;
                                          this script filters by row timestamps)

For each action window, prints matching prefetch rows, EVTX rows (grouped by
Channel / Provider / EventID), and shellbag rows whose FirstInteracted,
LastInteracted or LastWriteTime fall inside the window.

Usage: correlate_scenario.py <scenario_root>
"""

import csv
import sys
from datetime import datetime
from pathlib import Path


def parse_ts(s):
    if not s or not s.strip():
        return None
    s = s.strip().strip('"')
    if '.' in s:
        s = s.split('.')[0]
    if '+' in s:
        s = s.split('+')[0]
    if 'T' in s:
        s = s.replace('T', ' ')
    for fmt in ('%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M'):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    return None


def read_csv_bom(path):
    with open(path, 'r', encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def main(root):
    root = Path(root)
    win_dir = root / 'artefacts' / 'analysis' / 'windowed'
    windows_path = win_dir / 'windows.csv'
    if not windows_path.exists():
        print(f'ERROR: windows.csv not found at {windows_path}', file=sys.stderr)
        return 1

    windows = read_csv_bom(windows_path)
    for w in windows:
        w['_start'] = parse_ts(w['StartUtc'])
        w['_end'] = parse_ts(w['EndUtc'])

    # Prefetch: any file whose name contains 'prefetch' and ends '_windowed.csv'
    pf_rows = []
    for p in win_dir.glob('*prefetch*_windowed.csv'):
        for r in read_csv_bom(p):
            r['_t'] = parse_ts(r.get('RunTime', ''))
            if r['_t']:
                pf_rows.append(r)

    # EVTX: events_windowed.csv
    evtx_rows = []
    evtx_path = win_dir / 'events_windowed.csv'
    if evtx_path.exists():
        for r in read_csv_bom(evtx_path):
            r['_t'] = parse_ts(r.get('TimeCreated', ''))
            if r['_t']:
                evtx_rows.append(r)

    # ShellBags: NTUSER.csv and UsrClass.csv sitting flat in windowed/
    sb_rows = []
    for sb_file in ('NTUSER.csv', 'UsrClass.csv'):
        sb_path = win_dir / sb_file
        if not sb_path.exists():
            continue
        for r in read_csv_bom(sb_path):
            r['_hive'] = sb_file.replace('.csv', '')
            r['_first'] = parse_ts(r.get('FirstInteracted', ''))
            r['_last'] = parse_ts(r.get('LastInteracted', ''))
            r['_lwt'] = parse_ts(r.get('LastWriteTime', ''))
            sb_rows.append(r)

    print(f'# Correlation report: {root.name}')
    print(f'# Actions: {len(windows)} | Prefetch rows: {len(pf_rows)} | EVTX rows: {len(evtx_rows)} | ShellBag rows: {len(sb_rows)}')
    print()

    from collections import Counter
    for w in windows:
        s, e = w['_start'], w['_end']
        if not s or not e:
            continue
        print(f'## {w["Action"]}  {w["Note"]}   [{s.strftime("%H:%M:%S")} to {e.strftime("%H:%M:%S")}]')

        pf_hits = [r for r in pf_rows if s <= r['_t'] <= e]
        print(f'  PREFETCH ({len(pf_hits)}):')
        for r in pf_hits:
            exe = r['ExecutableName'].split('\\')[-1] if '\\' in r['ExecutableName'] else r['ExecutableName']
            print(f'    {r["_t"].strftime("%H:%M:%S")}  {exe}')

        ev_hits = [r for r in evtx_rows if s <= r['_t'] <= e]
        print(f'  EVTX ({len(ev_hits)}):')
        ev_group = Counter()
        for r in ev_hits:
            ev_group[(r['Channel'], r['Provider'], r['EventId'])] += 1
        for (chan, prov, eid), cnt in ev_group.most_common():
            sample = next((r for r in ev_hits if (r['Channel'], r['Provider'], r['EventId']) == (chan, prov, eid)), None)
            pd = ''
            if sample:
                pd = (sample.get('PayloadData1', '') or sample.get('MapDescription', '') or sample.get('Payload', ''))[:80].replace('\n', ' ')
            print(f'    {chan:22} {prov:35} EID {eid:6} x{cnt}  | {pd}')

        sb_hits = []
        for r in sb_rows:
            for t in (r['_first'], r['_last'], r['_lwt']):
                if t and s <= t <= e:
                    sb_hits.append((r, t))
                    break
        print(f'  SHELLBAG ({len(sb_hits)}):')
        for r, t in sb_hits:
            print(f'    {r["_hive"]}  {t.strftime("%H:%M:%S")}  {r.get("AbsolutePath", "")}')
        print()

    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: correlate_scenario.py <scenario_root>', file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
