# Project Audit Report: Zero-Trust Smart Campus NS-3

This report details the findings of the documentation audit against the actual NS-3 C++ implementation for the Zero-Trust Smart Campus project.

## 1. Comparison Table: Documentation Claim vs. Actual Implementation

| Feature | Documentation Claim (Original) | Actual Code Implementation | Status |
| :--- | :--- | :--- | :--- |
| **Node Count** | 60 Nodes | 58 Nodes (3 backbone + 55 department) | ⚠️ Exaggerated |
| **VLAN Architecture** | 9 VLANs (including VLAN 999 for Quarantine) | 8 CSMA Department Segments. No Quarantine VLAN exists. | ⚠️ Exaggerated |
| **Risk Decay Factor** | 0.97 per 2 seconds | 0.95 per 1 second | ⚠️ Inaccurate |
| **Unauthorized Access** | Increment risk by 15 points | Increments risk by 25 points | ⚠️ Inaccurate |
| **Port Scan Activity** | > 20 unique ports adds `ports * 5` risk | > 10 unique ports adds 30.0 risk | ⚠️ Inaccurate |
| **Traffic Anomaly** | > 80 pps adds `min(100, (pps-80)*2)` risk | > 80 pps adds `min(rate / 3.0, 40.0)` | ⚠️ Inaccurate |
| **Protocol Violation** | High-rate flood proxy | Triggered implicitly if traffic rate > 160 pps. | ⚠️ Inaccurate |
| **Rate Limiting (55-69)** | Bandwidth throttled to 10% (simulated TrafficControl) | State is logged only. No throttling is applied. | ❌ False Claim |
| **Quarantine (≥ 70)** | Interfaces disabled / isolated to VLAN 999 | `ipv4->SetDown(i)` called on all non-loopback interfaces. | ✅ Modified (VLAN claim false) |
| **Self-Healing** | "Re-apply quarantine if compromised" & "Quarantine-aware" | Reroutes traffic upon failure. Logs count of quarantined devices but relies on existing interface shutdown. | ⚠️ Modified |
| **Performance Results** | 98.3% improvement in detection, 99.5% in quarantine, 95.6% recovery | Values are hard-coded theoretical estimates in Python (`analyze-results.py`), not experimental simulation output. | ❌ False Claim |

---

## 2. "Paper-Ready" Assessment

For the purpose of writing an IEEE academic paper, use the following classifications to ensure scientific integrity and reproducibility:

### 🟢 SAFE TO CLAIM (Fully implemented and works)
* **Zero-Trust Access Matrix**: The policy engine accurately denies unauthorized cross-department traffic.
* **Behavioural Risk Scoring**: The multi-factor engine successfully calculates a dynamic risk score per source IP using a temporal decay factor.
* **Graduated State Tracking**: The system accurately classifies nodes into Normal, Warning, Rate-Limited, and Quarantined states based on their running score.
* **Interface-Level Quarantine**: Devices reaching the critical threshold are successfully isolated from the network by dynamically bringing down their IPv4 interfaces.
* **Autonomous Link Failure Recovery**: The self-healing controller successfully detects link failure via heartbeats and recomputes global routing tables to restore connectivity.

### 🟡 CLAIM WITH LIMITATION (Implemented partially, phrase carefully)
* **Rate-Limiting**: **Must be phrased carefully.** You can claim that the *scoring engine* categorizes devices into a "Rate-Limited" state for escalated severity. However, you must explicitly state that *traffic control/bandwidth throttling enforcement is left for future work* and is not simulated.
* **Protocol Violations**: You can claim protocol abuse detection, but clarify that it is inferred heuristically from extreme traffic rates (> 160 pps), rather than deep packet inspection of the protocol payload.
* **Quarantine-Aware Self-Healing**: You can claim that the network remains secure during failover because quarantined interfaces organically remain shut down. Do not claim an active "re-quarantine algorithm" runs during failover.

### 🔴 DO NOT CLAIM (Exists only in text, not in code)
* **VLAN 999 (Quarantine VLAN)**: Do not claim that compromised devices are moved to a separate VLAN. The simulation simply disables their network interfaces.
* **98%+ Performance Improvements**: Do not claim the hard-coded percentages in the README as "experimental results." You may present them as theoretical estimations comparing the implemented autonomous system's theoretical latency against human-in-the-loop manual responses.
* **Active Bandwidth Throttling**: Do not claim that a student's download speed drops to 10%. This does not happen in the simulation.
