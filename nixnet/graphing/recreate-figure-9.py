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
                data[rto][servers].append(goodput)

    fig, ax = plt.subplots(figsize=(7, 5))
    
    styles = {
        1: {'color': 'red', 'linestyle': '-', 'label': '1us RTOmin (~ none)'},
        5000: {'color': 'blue', 'linestyle': '--', 'label': '5ms RTOmin (Jiffy)'},
        200000: {'color': 'black', 'linestyle': ':', 'label': '200ms RTOmin (default)', 'alpha': 0.7}
    }
    
    for rto, style in styles.items():
        if rto in data:
            server_counts = sorted(data[rto].keys())
            
            y_vals = [sum(data[rto][s]) / len(data[rto][s]) for s in server_counts]
            
            ax.plot(server_counts, y_vals, linewidth=2, **style)

    ax.set_title("Num Servers vs Goodput\n(Fixed Block = 1.008MB, buffer = ~32KB)")
    ax.set_xlabel("Number of Servers")
    ax.set_ylabel("Goodput (Mbps)")
    
    ax.set_xlim(0, 16)
    ax.set_xticks(range(0, 17, 2))
    
    ax.set_ylim(0, 1000)
    ax.set_yticks(range(0, 1001, 100))
    
    ax.grid(True, linestyle=':', color='black', alpha=0.6)
    
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.15), frameon=False)
    
    plt.tight_layout()
    plt.savefig('figure-9-output_rto_servers_vs_goodput.png', dpi=300)

create_plot('out-graphs/summary.txt')