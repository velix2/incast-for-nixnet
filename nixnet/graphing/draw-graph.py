import matplotlib.pyplot as plt
import re
from collections import defaultdict

def create_plot(data_file):

    data = defaultdict(lambda: defaultdict(list))
    
    pattern = r"Server Count = (\d+), RTOmin = (\d+): Goodput: ([\d.]+)Mbps"
    
    with open(data_file, 'r') as f:
        for line in f:
            match = re.search(pattern, line)
            if match:
                servers = int(match.group(1))
                rto = int(match.group(2))
                goodput = float(match.group(3))
                data[servers][rto].append(goodput)

    rto_order = [200, 1000, 5000, 10000, 50000, 100000, 200000]
    x_labels = ['200u', '1m', '5m', '10m', '50m', '100m', '200m']
    
    fig, ax = plt.subplots(figsize=(7, 4.5))
    
    styles = {
        4: {'color': 'green', 'linestyle': ':', 'marker': 'D', 'label': '4'},
        8: {'color': 'red', 'linestyle': '-', 'marker': 'o', 'label': '8'},
        16: {'color': 'blue', 'linestyle': '--', 'marker': '^', 'label': '16'}
    }
    
    for servers in [4, 8, 16]:
        if servers in data:
            y_vals = []
            for rto in rto_order:
                if rto in data[servers] and data[servers][rto]:
                    avg = sum(data[servers][rto]) / len(data[servers][rto])
                    y_vals.append(avg)
                else:
                    y_vals.append(float('nan'))
                    
            ax.plot(x_labels, y_vals, **styles[servers], linewidth=2, markersize=4)

    ax.set_title("RTOmin vs Goodput\n(Block size = 1MB, buffer = 32KB (estimate))")
    ax.set_xlabel("RTOmin (seconds)")
    ax.set_ylabel("Goodput (Mbps)")
    
    ax.set_ylim(0, 1000)
    ax.set_yticks(range(0, 1001, 100))
    plt.xticks(rotation=90)
    
    ax.grid(True, linestyle=':', color='black', alpha=0.6)
    ax.legend(title="# servers", loc='lower left', frameon=False, labelspacing=0.2)
    
    plt.tight_layout()
    plt.savefig('output_servers_rto_vs_goodput.png', dpi=300)

create_plot('out-graphs/summary.txt')