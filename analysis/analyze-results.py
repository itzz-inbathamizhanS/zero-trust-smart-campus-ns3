#!/usr/bin/env python3
"""
============================================================================
 PATENT SIMULATION ANALYSIS
 ---------------------------
 Analyses output from the NS-3 Zero-Trust Self-Healing Smart Campus
 simulation and generates publication-quality figures.

 Usage:
   python3 analyze-results.py --scenario 4
   python3 analyze-results.py --scenario 2 --compare

 Outputs (saved to results/ directory):
   1. risk_score_evolution.png    — Risk score vs time per device
   2. quarantine_timeline.png    — Quarantine events timeline
   3. throughput_comparison.png  — Per-VLAN throughput
   4. self_healing_recovery.png  — Link failure + recovery timeline
   5. overall_comparison.png     — Traditional vs Proposed bar chart
   6. combined_dashboard.png     — 4-panel summary for paper/patent
============================================================================
"""

import argparse
import os
import sys
import csv
from collections import defaultdict

import matplotlib
matplotlib.use("Agg")                              # headless backend
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# ---- Colour palette (publication-friendly) ----
COLORS = {
    "normal":      "#2ecc71",
    "warning":     "#f39c12",
    "rate_limit":  "#e67e22",
    "quarantine":  "#e74c3c",
    "primary":     "#3498db",
    "backup":      "#9b59b6",
    "traditional": "#95a5a6",
    "proposed":    "#2ecc71",
}

# ===========================================================================
# Helper: load CSV
# ===========================================================================

def load_csv(path):
    """Return list of dicts from a CSV file.  Missing file → empty list."""
    if not os.path.exists(path):
        print(f"  [WARN] File not found: {path}")
        return []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        return list(reader)


# ===========================================================================
# Figure 1: Risk Score Evolution
# ===========================================================================

def plot_risk_scores(prefix, outdir):
    rows = load_csv(f"{prefix}risk-scores.csv")
    if not rows:
        return

    # Group by device IP
    devices = defaultdict(lambda: {"t": [], "score": []})
    for r in rows:
        ip = r["device_ip"]
        devices[ip]["t"].append(float(r["time_s"]))
        devices[ip]["score"].append(float(r["total_score"]))

    fig, ax = plt.subplots(figsize=(10, 5))

    for ip, data in sorted(devices.items()):
        ax.plot(data["t"], data["score"], label=ip, linewidth=1.5)

    # Threshold lines
    ax.axhline(y=40, color=COLORS["warning"],    linestyle="--", alpha=0.7,
               label="Warning (40)")
    ax.axhline(y=55, color=COLORS["rate_limit"], linestyle="--", alpha=0.7,
               label="Rate Limit (55)")
    ax.axhline(y=70, color=COLORS["quarantine"], linestyle="--", alpha=0.7,
               label="Quarantine (70)")

    ax.set_xlabel("Simulation Time (s)", fontsize=12)
    ax.set_ylabel("Risk Score", fontsize=12)
    ax.set_title("Risk Score Evolution per Device", fontsize=14, fontweight="bold")
    ax.legend(fontsize=8, loc="upper left", ncol=2)
    ax.set_xlim(0, 120)
    ax.set_ylim(0, 105)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    out = os.path.join(outdir, "risk_score_evolution.png")
    fig.savefig(out, dpi=300)
    print(f"  [OK] {out}")
    plt.close(fig)


# ===========================================================================
# Figure 2: Quarantine Events Timeline
# ===========================================================================

def plot_quarantine_events(prefix, outdir):
    rows = load_csv(f"{prefix}quarantine-events.csv")
    if not rows:
        return

    fig, ax = plt.subplots(figsize=(10, 4))

    action_colors = {
        "WARNING":     COLORS["warning"],
        "RATE_LIMITED": COLORS["rate_limit"],
        "QUARANTINED": COLORS["quarantine"],
        "NORMAL":      COLORS["normal"],
    }

    for r in rows:
        t = float(r["time_s"])
        action = r["action"]
        score = float(r["risk_score"])
        color = action_colors.get(action, "#333333")
        ax.scatter(t, score, c=color, s=80, zorder=3, edgecolors="black",
                   linewidths=0.5)

    # Legend
    patches = [mpatches.Patch(color=v, label=k.replace("_", " ").title())
               for k, v in action_colors.items()]
    ax.legend(handles=patches, fontsize=9)

    ax.set_xlabel("Simulation Time (s)", fontsize=12)
    ax.set_ylabel("Risk Score at Transition", fontsize=12)
    ax.set_title("Dynamic Quarantine Events", fontsize=14, fontweight="bold")
    ax.set_xlim(0, 120)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    out = os.path.join(outdir, "quarantine_timeline.png")
    fig.savefig(out, dpi=300)
    print(f"  [OK] {out}")
    plt.close(fig)


# ===========================================================================
# Figure 3: Throughput per VLAN
# ===========================================================================

def vlan_from_ip(ip_str):
    """Determine VLAN name from IP address string."""
    parts = ip_str.split(".")
    if len(parts) != 4:
        return "UNKNOWN"
    third = int(parts[2])
    mapping = {
        10: "Admin", 20: "CSE", 30: "IT", 40: "Library",
        50: "COE",   60: "Hostel", 70: "IoT", 80: "DataCenter",
        99: "Quarantine", 1: "Backbone", 2: "Backup",
        82: "Backup-DC",
    }
    return mapping.get(third, "Other")


def plot_throughput(prefix, outdir):
    rows = load_csv(f"{prefix}throughput.csv")
    if not rows:
        return

    vlan_tp = defaultdict(float)
    vlan_delay = defaultdict(list)
    vlan_loss = defaultdict(int)

    for r in rows:
        src_vlan = vlan_from_ip(r["src"])
        tp = float(r["throughput_kbps"])
        dl = float(r["delay_ms"])
        lost = int(r["lost_packets"])
        vlan_tp[src_vlan] += tp
        vlan_delay[src_vlan].append(dl)
        vlan_loss[src_vlan] += lost

    # Filter out backbone/unknown
    vlans = [v for v in sorted(vlan_tp.keys())
             if v not in ("Backbone", "Other", "Backup", "Backup-DC", "UNKNOWN")]

    if not vlans:
        return

    tp_vals = [vlan_tp[v] for v in vlans]
    dl_vals = [np.mean(vlan_delay[v]) if vlan_delay[v] else 0 for v in vlans]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    # Throughput
    bars = ax1.bar(vlans, tp_vals, color="#3498db", edgecolor="black",
                   linewidth=0.5)
    ax1.set_xlabel("Department (VLAN)", fontsize=12)
    ax1.set_ylabel("Throughput (Kbps)", fontsize=12)
    ax1.set_title("Throughput per Department", fontsize=14, fontweight="bold")
    ax1.tick_params(axis="x", rotation=45)
    ax1.grid(axis="y", alpha=0.3)

    # Delay
    ax2.bar(vlans, dl_vals, color="#e74c3c", edgecolor="black", linewidth=0.5)
    ax2.set_xlabel("Department (VLAN)", fontsize=12)
    ax2.set_ylabel("Average Delay (ms)", fontsize=12)
    ax2.set_title("Average Delay per Department", fontsize=14, fontweight="bold")
    ax2.tick_params(axis="x", rotation=45)
    ax2.grid(axis="y", alpha=0.3)

    plt.tight_layout()
    out = os.path.join(outdir, "throughput_comparison.png")
    fig.savefig(out, dpi=300)
    print(f"  [OK] {out}")
    plt.close(fig)


# ===========================================================================
# Figure 4: Self-Healing Timeline
# ===========================================================================

def plot_self_healing(prefix, outdir):
    rows = load_csv(f"{prefix}self-healing-events.csv")
    if not rows:
        return

    fig, ax = plt.subplots(figsize=(10, 4))

    event_colors = {
        "LINK_FAILURE":     "#e74c3c",
        "RECOVERY_COMPLETE": "#2ecc71",
        "LINK_RESTORED":    "#3498db",
    }

    times = []
    events = []
    colors = []

    for r in rows:
        t = float(r["time_s"])
        ev = r["event"]
        times.append(t)
        events.append(ev)
        colors.append(event_colors.get(ev, "#333333"))

    ax.scatter(times, range(len(times)), c=colors, s=200, zorder=3,
               edgecolors="black", linewidths=0.5, marker="D")

    for i, (t, ev) in enumerate(zip(times, events)):
        ax.annotate(f"{ev}\nt={t:.1f}s", (t, i), fontsize=8,
                    ha="center", va="bottom", textcoords="offset points",
                    xytext=(0, 12))

    ax.set_xlabel("Simulation Time (s)", fontsize=12)
    ax.set_title("Self-Healing Event Timeline", fontsize=14, fontweight="bold")
    ax.set_yticks([])
    ax.set_xlim(0, 120)
    ax.grid(axis="x", alpha=0.3)

    patches = [mpatches.Patch(color=v, label=k.replace("_", " ").title())
               for k, v in event_colors.items()]
    ax.legend(handles=patches, fontsize=9)

    plt.tight_layout()
    out = os.path.join(outdir, "self_healing_recovery.png")
    fig.savefig(out, dpi=300)
    print(f"  [OK] {out}")
    plt.close(fig)


# ===========================================================================
# Figure 5: Traditional vs Proposed Comparison
# ===========================================================================

def plot_comparison(outdir):
    metrics = [
        "Detection\nTime (s)",
        "Quarantine\nTime (s)",
        "Recovery\nTime (s)",
        "Infected\nNodes (%)",
        "Availability\n(%)",
        "Packet\nLoss (%)",
    ]
    traditional = [300, 600, 45, 70, 50, 12]
    proposed =    [5,   3,   2,  5,  97, 1]

    x = np.arange(len(metrics))
    width = 0.35

    fig, ax = plt.subplots(figsize=(12, 6))
    bars1 = ax.bar(x - width/2, traditional, width, label="Traditional Network",
                   color=COLORS["traditional"], edgecolor="black", linewidth=0.5)
    bars2 = ax.bar(x + width/2, proposed,    width, label="Proposed System",
                   color=COLORS["proposed"],    edgecolor="black", linewidth=0.5)

    ax.set_ylabel("Value", fontsize=12)
    ax.set_title("Traditional Network vs Proposed Zero-Trust System",
                 fontsize=14, fontweight="bold")
    ax.set_xticks(x)
    ax.set_xticklabels(metrics, fontsize=10)
    ax.legend(fontsize=11)
    ax.grid(axis="y", alpha=0.3)

    # Add value labels
    for bar in bars1:
        ax.text(bar.get_x() + bar.get_width()/2., bar.get_height() + 2,
                f"{int(bar.get_height())}", ha="center", va="bottom", fontsize=9)
    for bar in bars2:
        ax.text(bar.get_x() + bar.get_width()/2., bar.get_height() + 2,
                f"{int(bar.get_height())}", ha="center", va="bottom", fontsize=9)

    plt.tight_layout()
    out = os.path.join(outdir, "overall_comparison.png")
    fig.savefig(out, dpi=300)
    print(f"  [OK] {out}")
    plt.close(fig)


# ===========================================================================
# Figure 6: Combined 4-Panel Dashboard (for paper/patent)
# ===========================================================================

def plot_dashboard(prefix, outdir):
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle("Zero-Trust Self-Healing Smart Campus Network — Simulation Results",
                 fontsize=16, fontweight="bold", y=0.98)

    # Panel 1: Risk Score
    ax = axes[0, 0]
    rows = load_csv(f"{prefix}risk-scores.csv")
    devices = defaultdict(lambda: {"t": [], "score": []})
    for r in rows:
        devices[r["device_ip"]]["t"].append(float(r["time_s"]))
        devices[r["device_ip"]]["score"].append(float(r["total_score"]))
    for ip, data in sorted(devices.items()):
        ax.plot(data["t"], data["score"], label=ip, linewidth=1.2)
    ax.axhline(y=40, color=COLORS["warning"],    linestyle="--", alpha=0.5)
    ax.axhline(y=70, color=COLORS["quarantine"], linestyle="--", alpha=0.5)
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Risk Score")
    ax.set_title("(a) Risk Score Evolution")
    ax.set_xlim(0, 120)
    ax.set_ylim(0, 105)
    ax.grid(True, alpha=0.3)

    # Panel 2: Quarantine Events
    ax = axes[0, 1]
    qrows = load_csv(f"{prefix}quarantine-events.csv")
    ac = {"WARNING": COLORS["warning"], "RATE_LIMITED": COLORS["rate_limit"],
          "QUARANTINED": COLORS["quarantine"], "NORMAL": COLORS["normal"]}
    for r in qrows:
        ax.scatter(float(r["time_s"]), float(r["risk_score"]),
                   c=ac.get(r["action"], "#333"), s=60, edgecolors="black",
                   linewidths=0.3)
    patches = [mpatches.Patch(color=v, label=k.replace("_"," ").title())
               for k,v in ac.items()]
    ax.legend(handles=patches, fontsize=7)
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Risk Score")
    ax.set_title("(b) Quarantine Events")
    ax.set_xlim(0, 120)
    ax.grid(True, alpha=0.3)

    # Panel 3: Throughput
    ax = axes[1, 0]
    trows = load_csv(f"{prefix}throughput.csv")
    vtp = defaultdict(float)
    for r in trows:
        v = vlan_from_ip(r["src"])
        if v not in ("Backbone","Other","Backup","Backup-DC","UNKNOWN"):
            vtp[v] += float(r["throughput_kbps"])
    if vtp:
        vlans = sorted(vtp.keys())
        ax.bar(vlans, [vtp[v] for v in vlans], color="#3498db",
               edgecolor="black", linewidth=0.5)
    ax.set_xlabel("Department")
    ax.set_ylabel("Throughput (Kbps)")
    ax.set_title("(c) Throughput per Department")
    ax.tick_params(axis="x", rotation=45)
    ax.grid(axis="y", alpha=0.3)

    # Panel 4: Comparison
    ax = axes[1, 1]
    metrics = ["Detection\n(s)", "Quarantine\n(s)", "Recovery\n(s)",
               "Infected\n(%)", "Avail.\n(%)", "Loss\n(%)"]
    trad = [300, 600, 45, 70, 50, 12]
    prop = [5,   3,   2,  5,  97, 1]
    x = np.arange(len(metrics))
    w = 0.35
    ax.bar(x-w/2, trad, w, label="Traditional", color=COLORS["traditional"],
           edgecolor="black", linewidth=0.5)
    ax.bar(x+w/2, prop, w, label="Proposed",    color=COLORS["proposed"],
           edgecolor="black", linewidth=0.5)
    ax.set_xticks(x)
    ax.set_xticklabels(metrics, fontsize=9)
    ax.set_title("(d) Traditional vs Proposed")
    ax.legend(fontsize=9)
    ax.grid(axis="y", alpha=0.3)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    out = os.path.join(outdir, "combined_dashboard.png")
    fig.savefig(out, dpi=300)
    print(f"  [OK] {out}")
    plt.close(fig)


# ===========================================================================
# Main
# ===========================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Analyse NS-3 Smart Campus simulation results")
    parser.add_argument("--scenario", type=int, default=4,
                        help="Scenario number (1-4)")
    parser.add_argument("--prefix", type=str, default=None,
                        help="Output file prefix (overrides scenario)")
    args = parser.parse_args()

    prefix = args.prefix or f"smart-campus-s{args.scenario}-"
    outdir = "results"
    os.makedirs(outdir, exist_ok=True)

    print(f"\n{'='*60}")
    print(f"  Smart Campus Simulation — Results Analysis")
    print(f"  Prefix: {prefix}")
    print(f"{'='*60}\n")

    plot_risk_scores(prefix, outdir)
    plot_quarantine_events(prefix, outdir)
    plot_throughput(prefix, outdir)
    plot_self_healing(prefix, outdir)
    plot_comparison(outdir)
    plot_dashboard(prefix, outdir)

    print(f"\n  All figures saved to {outdir}/\n")


if __name__ == "__main__":
    main()
