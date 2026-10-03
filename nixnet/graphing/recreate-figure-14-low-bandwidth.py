import matplotlib.pyplot as plt
import re
from collections import defaultdict

def create_plot(data_file):
    data = defaultdict(lambda: defaultdict(list))
    
    pattern = r"Server Count = (\d+), Quickack = (\d+): Goodput: ([\d.]+)Mbps"
    
    with open(data_file, 'r') as f:
        for line in f:
            match = re.search(pattern, line)
            if match:
                servers = int(match.group(1))
                qa = int(match.group(2))
                goodput = float(match.group(3))
                data[qa][servers].append(goodput)

    fig, ax = plt.subplots(figsize=(7, 5))
    
    styles = {
        1: {'color': 'red', 'linestyle': '-', 'marker': '.', 'label': 'Delayed ACK Disabled'},
        0: {'color': 'black', 'linestyle': ':', 'marker': 'v', 'label': 'Delayed ACK 40ms'},

    }
    
    for qa, style in styles.items():
        if qa in data:
            server_counts = sorted(data[qa].keys())
            
            y_vals = [sum(data[qa][s]) / len(data[qa][s]) for s in server_counts]
            
            ax.plot(server_counts, y_vals, linewidth=2, **style)

    ax.set_title("Num Servers vs Goodput (DelayedACK Client)\n(Fixed Block = ~1MB, buffer = ~32KB)")
    ax.set_xlabel("Number of Servers")
    ax.set_ylabel("Goodput (Mbps)")
    
    ax.set_xlim(0, 16)
    ax.set_xticks(range(0, 17, 2))
    
    ax.set_ylim(0, 1000)
    ax.set_yticks(range(0, 1001, 100))
    
    ax.grid(True, linestyle=':', color='black', alpha=0.6)
    
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.15), frameon=False)
    
    plt.tight_layout()
    plt.savefig('low-bandwidth-figure-14-output_rto_servers_vs_goodput.png', dpi=300)

create_plot('out-graphs/summary.txt')