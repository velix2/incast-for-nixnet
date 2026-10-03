from collections import defaultdict
import re
import matplotlib.pyplot as plt


def create_plot(data_file):
  data = defaultdict(lambda: defaultdict(list))

  pattern = r"Server Count = (\d+), Quickack = (\d+): Goodput: ([\d.]+)Mbps"

  with open(data_file, "r") as f:
    for line in f:
      match = re.search(pattern, line)
      if match:
        servers = int(match.group(1))
        qa = int(match.group(2))
        goodput = float(match.group(3))
        data[qa][servers].append(goodput)

  # Compute averages per quickack setting
  averages = {}
  for qa in [0, 1]:
    if qa in data:
      averages[qa] = {s: sum(vals) / len(vals) for s, vals in data[qa].items()}

  fig, ax = plt.subplots(figsize=(7, 5))

  # Calculate and plot relative goodput percentage (QA Off / QA On)
  if 0 in averages and 1 in averages:
    common_servers = sorted(set(averages[0].keys()) & set(averages[1].keys()))
    pct_vals = [
        (averages[0][s] / averages[1][s]) * 100 if averages[1][s] != 0 else 0
        for s in common_servers
    ]

    ax.plot(
        common_servers,
        pct_vals,
        color="blue",
        linestyle="-",
        marker="s",
        linewidth=2,
        label="Relative Goodput (Delayed / No Delayed ACKs)",
    )

  ax.set_title(
      "Num Servers vs Relative Goodput (DelayedACK Client)\n(Fixed Block = ~1MB,"
      " buffer = ~32KB)"
  )
  ax.set_xlabel("Number of Servers")
  ax.set_ylabel("Relative Goodput (%)")

  ax.set_xlim(0, 16)
  ax.set_xticks(range(0, 17, 2))

  ax.set_ylim(0, 110)
  ax.set_yticks(range(0, 111, 10))

  ax.grid(True, linestyle=":", color="black", alpha=0.6)
  ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.15), frameon=False)

  plt.tight_layout()
  plt.savefig("relative-figure-14-output_rto_servers_vs_goodput.png", dpi=300)


create_plot("out-graphs/summary.txt")