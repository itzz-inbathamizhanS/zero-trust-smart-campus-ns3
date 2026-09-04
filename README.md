# Zero-Trust Self-Healing Smart Campus Network — NS-3 Simulation

## Patent Title
**System and Method for Risk-Based Dynamic Network Quarantine with Autonomous Self-Healing in Zero-Trust Campus Networks**

---

## Quick Start (Windows — WSL Required)

### Step 1: Install WSL
Open PowerShell as Administrator and run:
```powershell
wsl --install -d Ubuntu-22.04
```
Restart your PC if prompted. After restart, set up your Ubuntu username/password.

### Step 2: Copy project to WSL
```powershell
# From PowerShell — copy project into WSL
wsl cp -r /mnt/d/CN/ns3-smart-campus ~/ns3-smart-campus
```

### Step 3: Run the setup script
```bash
# Inside WSL terminal
cd ~/ns3-smart-campus
chmod +x setup-ns3.sh
./setup-ns3.sh
```
This will:
- Install all dependencies (gcc, cmake, python3, etc.)
- Download NS-3 v3.41
- Build NS-3
- Copy and compile the simulation

**⏱ First-time setup takes 15-30 minutes.**

### Step 4: Run the simulation
```bash
cd ~/ns-allinone-3.41/ns-3.41

# Scenario 1: Normal zero-trust operation (baseline)
./ns3 run "smart-campus --scenario=1"

# Scenario 2: Malware attack + dynamic quarantine
./ns3 run "smart-campus --scenario=2"

# Scenario 3: Link failure + self-healing
./ns3 run "smart-campus --scenario=3"

# Scenario 4: Combined attack + link failure (RECOMMENDED)
./ns3 run "smart-campus --scenario=4"

# With verbose logging:
./ns3 run "smart-campus --scenario=4 --verbose=true"
```

### Step 5: Analyse results
```bash
# Copy output files to analysis directory
cp smart-campus-s4-*.csv ~/ns3-smart-campus/analysis/
cp smart-campus-s4-*.xml ~/ns3-smart-campus/analysis/

# Generate publication-quality graphs
cd ~/ns3-smart-campus/analysis
python3 analyze-results.py --scenario 4

# Results saved in results/ directory
ls results/
```

### Step 6: View NetAnim visualisation (optional)
```bash
cd ~/ns-allinone-3.41/netanim-3.109
./NetAnim
# Open: smart-campus-s4-animation.xml
```

---

## Project Structure

```
ns3-smart-campus/
├── README.md                          ← This file
├── setup-ns3.sh                       ← Automated NS-3 installation
├── scratch/
│   └── smart-campus/
│       └── smart-campus-network.cc    ← Main simulation (900+ lines)
│           ├── RiskScoringEngine      ← Patent Claim 1
│           ├── ZeroTrustPolicy        ← Access control matrix
│           ├── QuarantineController   ← Patent Claim 2
│           ├── SelfHealingController  ← Patent Claim 3
│           ├── MaliciousTrafficApp    ← Attack simulator
│           ├── TrafficMonitorForward  ← Behavioural detection
│           └── main()                 ← Topology + scenarios
├── analysis/
│   └── analyze-results.py             ← Generate graphs
└── docs/
    └── patent-specification.md        ← Patent draft
```

---

## Campus Topology (60 Nodes)

```
Internet Server
       │
   P2P (1 Gbps)
       │
   CORE ROUTER ────── P2P (backup) ────── DIST SWITCH 2
       │                                        │
       ├── CSMA: Admin VLAN 10     (4 nodes)    │
       ├── CSMA: CSE VLAN 20      (10 nodes)   │
       ├── CSMA: IT VLAN 30       (10 nodes)   │
       ├── CSMA: Library VLAN 40   (6 nodes)    │
       ├── CSMA: COE VLAN 50       (4 nodes)    │
       ├── CSMA: Hostel VLAN 60    (8 nodes)    │
       ├── CSMA: IoT VLAN 70       (6 nodes)    │
       ├── CSMA: DataCenter VLAN 80 (7 nodes) ──┘ (redundant path)
       └── [Quarantine VLAN 999]
```

---

## IP Addressing Plan

| VLAN | Department    | Subnet          | Nodes |
|------|--------------|-----------------|-------|
| 10   | Admin        | 10.0.10.0/24    | 4     |
| 20   | CSE          | 10.0.20.0/24    | 10    |
| 30   | IT           | 10.0.30.0/24    | 10    |
| 40   | Library      | 10.0.40.0/24    | 6     |
| 50   | COE          | 10.0.50.0/24    | 4     |
| 60   | Hostel       | 10.0.60.0/24    | 8     |
| 70   | IoT Lab      | 10.0.70.0/24    | 6     |
| 80   | DataCenter   | 10.0.80.0/24    | 7     |
| 999  | Quarantine   | 10.0.99.0/24    | —     |

---

## Risk Scoring Algorithm (Patent Core)

```
RiskScore(device) = 0.35·A + 0.25·T + 0.25·P + 0.15·V

Where:
  A = Unauthorised access attempt score (0-100)
  T = Traffic volume anomaly score (0-100)
  P = Port scan activity score (0-100)
  V = Protocol violation score (0-100)
```

### Graduated Response

| Risk Score | Action         | Network Effect                        |
|-----------|----------------|---------------------------------------|
| 0 – 39    | ✅ Normal      | Full access per zero-trust policy     |
| 40 – 54   | ⚠️ Warning    | Alert generated, logging intensified  |
| 55 – 69   | 🟠 Rate Limit | Bandwidth throttled                   |
| 70 – 100  | 🔴 Quarantine | Full isolation, interface disabled    |

---

## Simulation Scenarios

| Scenario | Description | Events |
|----------|------------|--------|
| 1 | Normal operation | Baseline legitimate traffic only |
| 2 | Attack + Quarantine | t=30s: malware attack begins → risk score rises → quarantine activates |
| 3 | Self-Healing | t=60s: primary DC link fails → backup activates → t=90s: link restored |
| 4 | Combined | Attack at t=30s + Link failure at t=60s + Quarantine + Self-healing |

---

## Output Files

Each run produces these files (prefixed with `smart-campus-s{N}-`):

| File | Contents |
|------|----------|
| `risk-scores.csv` | Risk score evolution per device over time |
| `quarantine-events.csv` | Quarantine level transitions with timestamps |
| `self-healing-events.csv` | Link failure detection and recovery log |
| `throughput.csv` | Per-flow throughput, delay, and packet loss |
| `flowmon.xml` | NS-3 FlowMonitor XML (detailed flow statistics) |
| `animation.xml` | NetAnim visualisation file |

---

## Generated Graphs

Running `analyze-results.py` produces:

1. **risk_score_evolution.png** — Risk score vs time (shows detection speed)
2. **quarantine_timeline.png** — Quarantine events with graduated levels
3. **throughput_comparison.png** — Per-department throughput and delay
4. **self_healing_recovery.png** — Link failure and recovery timeline
5. **overall_comparison.png** — Traditional vs Proposed bar chart
6. **combined_dashboard.png** — 4-panel summary (paper/patent ready)

---

## Expected Results (Scenario 4)

| Metric | Traditional | Proposed |
|--------|------------|----------|
| Detection Time | 5-30 min | < 5 sec |
| Quarantine Time | 10-60 min | < 3 sec |
| Recovery Time | 30-60 sec | < 2 sec |
| Infected Nodes | 60-80% | < 5% |
| Availability | 40-60% | > 95% |
| Packet Loss | 8-15% | < 1% |

---

## Zero-Trust Access Policy Matrix

| Source → Dest | Admin | CSE | IT | Library | COE | Hostel | IoT | DC |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Admin** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **CSE** | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **IT** | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Library** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **COE** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Hostel** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| **IoT** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Quarantine** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## Team Members

| Member | Role | Responsibility |
|--------|------|---------------|
| Inbathamizhan S | Implementation Lead | NS-3 simulation, Packet Tracer, block diagram |
| Sadhik | Research Lead | Literature survey, research gap, references |
| Judson | Documentation Lead | Problem statement, objectives, abstract, PPT |
| Surya | Analysis Lead | Existing/proposed system, advantages, conclusion |
| Member 5 | Presentation Lead | Diagrams, formatting, presentation graphics |

---

## Troubleshooting

### Build errors
```bash
# Clean and rebuild
cd ~/ns-allinone-3.41/ns-3.41
./ns3 clean
./ns3 configure --build-profile=debug --enable-examples
./ns3 build
```

### "Command not found" for ns3
```bash
# Make sure you're in the NS-3 directory
cd ~/ns-allinone-3.41/ns-3.41
ls ns3  # Should show the ns3 script
```

### WSL display issues (NetAnim)
```bash
# Install X server on Windows (VcXsrv or WSLg)
# For WSLg (Windows 11), it works automatically
# For Windows 10, install VcXsrv and:
export DISPLAY=:0
```

---

## License
This simulation is developed for academic and research purposes.
Patent pending — do not distribute without authorisation.
