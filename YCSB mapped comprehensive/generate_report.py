import os
import glob
import math

RESULTS_DIR = "/results"

def parse_log(filepath):
    # Initialize with None to distinguish between "0 latency" and "missing metric"
    m = {'t': 0.0, 'r': None, 'u': None, 's': None, 'i': None}
    try:
        with open(filepath, 'r') as f:
            for line in f:
                parts = line.split(',')
                try:
                    val = float(parts[-1].strip())
                except ValueError:
                    continue # Skip lines where conversion fails

                if '[OVERALL], Throughput' in line:
                    m['t'] = val
                elif '[READ], AverageLatency' in line:
                    m['r'] = val
                elif '[UPDATE], AverageLatency' in line:
                    m['u'] = val
                elif '[SCAN], AverageLatency' in line:
                    m['s'] = val
                elif '[INSERT], AverageLatency' in line:
                    m['i'] = val
    except:
        pass
    return m

def fmt_lat(val):
    if val is None: return "-"
    if math.isnan(val): return "0.0"
    return "{:.1f}".format(val)

def safe_avg(lst):
    # Filter out None and NaN before averaging
    valid_items = [x for x in lst if x is not None and not math.isnan(x)]
    if not valid_items: return 0.0
    return sum(valid_items) / len(valid_items)

def print_row(cols, w=15):
    line = "".join([str(c).ljust(w) for c in cols])
    print(line)

def main():
    files = glob.glob(os.path.join(RESULTS_DIR, "*_wl*.txt"))
    data = []
    
    for fp in files:
        fname = os.path.basename(fp).replace('.txt', '')
        parts = fname.split('_')
        
        if len(parts) >= 3:
            wl = parts[-1].replace('wl', '').upper()
            dbtype = parts[0].upper()
            ident = "_".join(parts[1:-1])
            data.append({'type': dbtype, 'id': ident, 'wl': wl, 'm': parse_log(fp)})

    print("\n" + "="*80)
    print("DETAILED PERFORMANCE REPORT")
    print("="*80)
    print_row(["DB", "Table/Coll", "WL", "Ops/Sec", "Read(us)", "Upd(us)", "Scan(us)"])
    print("-" * 105)
    
    data.sort(key=lambda x: (x['type'], x['id'], x['wl']))
    
    summary = {} 

    for d in data:
        m = d['m']
        print_row([
            d['type'], 
            d['id'][:14], 
            d['wl'], 
            "{:.1f}".format(m['t']), 
            fmt_lat(m['r']),
            fmt_lat(m['u']),
            fmt_lat(m['s'])
        ])
        
        k = (d['type'], d['wl'])
        if k not in summary: 
            summary[k] = {'t':[], 'r':[], 'u':[], 's':[]}
        
        if m['t'] > 0: summary[k]['t'].append(m['t'])
        if m['r'] is not None: summary[k]['r'].append(m['r'])
        if m['u'] is not None: summary[k]['u'].append(m['u'])
        if m['s'] is not None: summary[k]['s'].append(m['s'])

    print("\n" + "="*80)
    print("COMPARATIVE SUMMARY (AVERAGES)")
    print("="*80)
    print_row(["Type", "Workload", "Avg Ops/Sec", "Avg Read", "Avg Upd", "Avg Scan"])
    print("-" * 90)
    
    for k in sorted(summary.keys()):
        s = summary[k]
        
        avg_t = safe_avg(s['t'])
        avg_r = safe_avg(s['r'])
        avg_u = safe_avg(s['u'])
        avg_s = safe_avg(s['s'])
        
        print_row([
            k[0], 
            k[1], 
            "{:.1f}".format(avg_t), 
            "{:.1f}".format(avg_r) if avg_r > 0 else "-",
            "{:.1f}".format(avg_u) if avg_u > 0 else "-",
            "{:.1f}".format(avg_s) if avg_s > 0 else "-"
        ])
    print("\n")

if __name__ == "__main__":
    main()