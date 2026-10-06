# 📖 Technical Glossary — Every Term Explained Simply

> **For Review 2 | All 5 Members Must Know These Terms**
> If Sir asks "What is ___?", use these answers.

---

## A

### ACL (Access Control List)
**Simple:** A list of rules that says "allow this traffic" or "deny this traffic."  
**In our project:** Our Zero-Trust Access Matrix is essentially an ACL. For example, CSE students can access the Library and Data Center, but NOT Administration or COE. Any packet violating this matrix is dropped and flagged.  
**If Sir asks:** *"Sir, an ACL is a set of permit/deny rules applied to a router interface. In our project, the Core Router checks every forwarded packet against our Zero-Trust policy matrix. If a CSE student tries to reach the Admin subnet, the packet is dropped and the source's risk score is incremented by 25 points."*

---

### ARP (Address Resolution Protocol)
**Simple:** Converts an IP address (like 10.0.20.2) into a MAC address (like AA:BB:CC:DD:EE:FF) so devices on the same LAN can talk to each other.  
**In our project:** ARP works automatically inside each CSMA segment (VLAN). When a CSE laptop wants to send data, ARP resolves the router's MAC address first.

---

## B

### Backbone
**Simple:** The main "highway" link that carries traffic between the major parts of a network.  
**In our project:** The backbone is the Point-to-Point (P2P) link between the Internet Server and the Core Router using the `10.0.1.0/24` subnet at 1 Gbps speed.

---

### Bandwidth
**Simple:** The maximum amount of data that can travel through a network connection per second. Think of it like the width of a water pipe — wider pipe = more water flow.  
**In our project:** Each CSMA department link runs at 100 Mbps. The backbone runs at 1 Gbps. Normal traffic per node is 500 Kbps. The attacker floods at 5 Mbps.

---

## C

### CSMA (Carrier Sense Multiple Access)
**Simple:** A method where devices on a shared cable "listen before talking." If the cable is busy, they wait. If it's free, they send data.  
**In our project:** All 8 department segments (Admin, CSE, IT, Library, COE, Hostel, IoT, Data Center) use CSMA channels at 100 Mbps. Think of each department as having a shared Ethernet cable.  
**If Sir asks:** *"CSMA stands for Carrier Sense Multiple Access. Before sending data, a device checks (senses) if the shared medium (carrier) is busy. If busy, it waits. If free, it transmits. Our 8 department VLANs all use CSMA channels in NS-3."*

---

### CSV (Comma-Separated Values)
**Simple:** A simple file format where each line is a row and values are separated by commas. Excel can open it.  
**In our project:** The simulation outputs 4 CSV files: `risk-scores.csv`, `quarantine-events.csv`, `self-healing-events.csv`, and `throughput.csv`.

---

## D

### DHCP (Dynamic Host Configuration Protocol)
**Simple:** Automatically assigns IP addresses to devices when they connect to the network. Like a receptionist giving visitor badges.  
**In our project:** We have a DHCP Server in the Data Center (one of the 7 DC servers). In the simulation, IP addresses are statically assigned by NS-3's `Ipv4AddressHelper`, but in a real campus, DHCP would handle this.

---

### DNS (Domain Name System)
**Simple:** Translates human-friendly names (like www.google.com) into IP addresses (like 142.250.182.14). It's the "phone book" of the internet.  
**In our project:** We have a DNS Server at `10.0.80.4` in our Data Center. Library nodes send their traffic to the DNS server.

---

### DoS / DDoS (Denial of Service / Distributed Denial of Service)
**Simple:** An attack where someone floods a server with so much fake traffic that real users can't access it. Like 1000 people blocking a door so nobody can enter.  
**In our project:** The attacker at `10.0.20.2` performs a traffic flood at 5 Mbps (50 packets every 0.5 seconds), which our Traffic Monitor detects when the rate exceeds 80 packets/second.

---

## E

### ERP (Enterprise Resource Planning)
**Simple:** Software used by organizations to manage daily activities like accounting, student records, HR, and procurement.  
**In our project:** The ERP Server (`10.0.80.1`) is the main target. Admin PCs access ERP for management, and the attacker tries to reach it through port scanning.

---

## F

### Firewall
**Simple:** A security device/software that monitors incoming and outgoing network traffic and decides whether to allow or block it based on rules.  
**In our project:** Our Core Router acts as a firewall. It inspects every forwarded packet using the `TrafficMonitorForward` callback and checks it against the Zero-Trust Access Matrix. Unlike a traditional firewall that just blocks/allows, ours also calculates a risk score.  
**If Sir asks:** *"A firewall is a network security system that monitors and controls traffic based on predetermined rules. Our Core Router functions as an advanced firewall — instead of simple allow/deny, it continuously evaluates behavioural signals and assigns a risk score to each device."*

---

### FlowMonitor
**Simple:** An NS-3 tool that tracks every data flow in the simulation and measures throughput, delay, and packet loss.  
**In our project:** `FlowMonitorHelper` is installed on all nodes. At the end of the simulation, it reports: Total Flows (150), Total Throughput (25,030 Kbps), Average Delay (1.85 ms), and Packet Loss Rate (0.68%).

---

## G

### Gateway
**Simple:** A device that connects two different networks. Like a door between two rooms.  
**In our project:** The Core Router is the default gateway for all 8 department VLANs. All inter-VLAN traffic must pass through it.

---

## H

### Heartbeat
**Simple:** A periodic signal sent to check if a device or link is still alive. Like checking if someone is still on the phone by saying "hello?"  
**In our project:** The Self-Healing Controller sends heartbeats every 0.5 seconds to verify the primary Data Center link is working. If no reply comes back within 0.5s, it declares a link failure and activates the backup path.  
**If Sir asks:** *"Our heartbeat mechanism runs every 500 milliseconds. If the primary link doesn't respond, the controller activates the backup distribution switch and recomputes all routing tables."*

---

### Hierarchical Network Design
**Simple:** Organizing a network into layers (tiers), each with a specific job. Like floors in a building — ground floor (access), middle floor (distribution), top floor (core).  
**In our project:**
- **Core Layer:** The Core Router (`10.0.1.1`) — handles all routing, security decisions, and policy enforcement
- **Distribution Layer:** Distribution Switch 2 (Backup Switch) — provides redundant paths
- **Access Layer:** 8 CSMA department segments where end devices connect

---

## I

### Inter-VLAN Routing
**Simple:** Moving data between different VLANs. Since VLANs are isolated by default, a router is needed to pass traffic between them.  
**In our project:** The Core Router connects to all 8 VLANs. When a CSE student (`10.0.20.x`) wants to access the Web Server (`10.0.80.5`), the packet goes from the CSE VLAN → Core Router → Data Center VLAN. The router checks the Zero-Trust policy before forwarding.  
**If Sir asks:** *"Inter-VLAN routing is the process of forwarding traffic between different VLANs using a Layer 3 device. In our design, the Core Router performs inter-VLAN routing and simultaneously applies our Zero-Trust access policy."*

---

### IP Address
**Simple:** A unique number assigned to every device on a network, like a home address for your computer.  
**In our project:** We use the `10.0.X.0/24` scheme where X identifies the department (10=Admin, 20=CSE, 30=IT, etc.).

---

### IPv4
**Simple:** The fourth version of the Internet Protocol, using 32-bit addresses written as four numbers separated by dots (e.g., 10.0.20.2).  
**In our project:** All addressing uses IPv4. The NS-3 `Ipv4AddressHelper` assigns addresses like `10.0.10.1`, `10.0.20.1`, etc.

---

## L

### Lateral Movement
**Simple:** When a hacker who has compromised one device uses it to attack other devices on the same network. Moving "sideways" to spread.  
**In our project:** Our Zero-Trust policy blocks lateral movement. A compromised CSE laptop (`10.0.20.2`) tries to reach Admin (`10.0.10.x`) and COE (`10.0.50.x`) — both are denied by the access matrix, and each attempt adds 25 risk points.

---

### Link Failure
**Simple:** When a physical cable or connection between two network devices breaks or stops working.  
**In our project:** At t=60s in Scenario 3 and 4, we simulate the primary Data Center link going down. The router's CSMA interface to DC is disabled (`ipv4->SetDown()`).

---

## M

### MAC Address (Media Access Control Address)
**Simple:** A hardware address burned into every network card. Like a serial number for your network interface. Written as six pairs of hex digits (AA:BB:CC:DD:EE:FF).  
**In our project:** NS-3 automatically assigns MAC addresses to all CSMA and P2P devices.

---

### Malware
**Simple:** Malicious software designed to damage or exploit computers and networks. Includes viruses, worms, trojans, ransomware.  
**In our project:** We simulate a malware-infected CSE student laptop that performs port scanning, unauthorized access attempts, and traffic flooding.

---

## N

### NAC (Network Access Control)
**Simple:** A security approach that checks every device before allowing it to connect to the network. Like an ID check before entering a building.  
**In our project:** Our Zero-Trust model is an advanced form of NAC — it doesn't just check at connection time, it continuously monitors every device's behaviour throughout the session.

---

### NetAnim
**Simple:** A graphical tool that shows an animated visualization of an NS-3 simulation. You can see packets moving between nodes in real-time.  
**In our project:** We generate a `.xml` animation file for each scenario. Opening it in NetAnim shows the 58 nodes with color-coded departments, and you can watch packets flow and the attacker turn red when quarantined.

---

### Network Segmentation
**Simple:** Dividing a large network into smaller, isolated pieces. Like dividing an office building into locked departments.  
**In our project:** We segment the campus into 8 separate VLANs: Admin (VLAN 10), CSE (VLAN 20), IT (VLAN 30), Library (VLAN 40), COE (VLAN 50), Hostel (VLAN 60), IoT Lab (VLAN 70), Data Center (VLAN 80). Traffic between segments must pass through the Core Router.  
**If Sir asks:** *"Network segmentation reduces the attack surface. If malware infects a CSE laptop, it cannot spread to the Administration or IoT Lab because they are on separate VLANs with strict access rules."*

---

### NS-3 (Network Simulator 3)
**Simple:** An open-source network simulator used for research and education. You write C++ code to create virtual networks and test how they behave.  
**Why not Packet Tracer?** Packet Tracer only supports pre-built Cisco commands and cannot implement custom algorithms. NS-3 lets us write our own Risk Scoring Engine, Traffic Monitor, and Quarantine Controller as custom C++ classes.

---

## O

### OSPF (Open Shortest Path First)
**Simple:** A routing protocol that automatically finds the shortest path for data to travel through a network. Every router shares its link information with neighbours, and they all calculate the best routes.  
**In our project:** We use NS-3's `Ipv4GlobalRoutingHelper::PopulateRoutingTables()` which simulates OSPF-like behaviour. When the primary link fails, we call `RecomputeRoutingTables()` to simulate OSPF re-convergence through the backup path.  
**If Sir asks:** *"OSPF is a link-state dynamic routing protocol. Each router maintains a complete map of the network topology and uses Dijkstra's algorithm to calculate the shortest path. However, OSPF is security-agnostic — it doesn't know about quarantined devices. That's exactly the gap our quarantine-aware self-healing addresses."*

---

## P

### P2P (Point-to-Point)
**Simple:** A direct connection between exactly two devices, like a private road between two buildings.  
**In our project:** The backbone (Internet Server ↔ Core Router) and the backup link (Core Router ↔ Backup Switch) use P2P connections at 1 Gbps with 2ms delay.

---

### Packet
**Simple:** A small chunk of data being sent over a network. Large messages are broken into many small packets, sent individually, and reassembled at the destination.  
**In our project:** Legitimate traffic sends 512-byte packets. The attacker's port scan sends 64-byte packets, and its flood sends 1024-byte packets.

---

### Packet Loss
**Simple:** When data packets fail to reach their destination. Like letters getting lost in the mail.  
**In our project:** Scenario 4 shows a packet loss rate of only 0.68%, meaning 99.32% of all packets arrived successfully even during the attack and link failure.

---

### PEP (Policy Enforcement Point)
**Simple:** The device or software component that actually enforces security policies (allows/blocks traffic).  
**In our project:** The Core Router is the PEP. It intercepts every forwarded packet using the `UnicastForward` trace callback and enforces the Zero-Trust Access Matrix.

---

### Port (Network Port)
**Simple:** A number (0–65535) that identifies a specific service on a device. Like apartment numbers in a building — the IP is the building address, the port is the apartment number.  
Common ports: HTTP = 80, HTTPS = 443, DNS = 53, SSH = 22.  
**In our project:** The attacker scans ports 1 to 100 on the ERP server. Our system detects a port scan when a single source accesses more than 10 unique ports within 5 seconds.

---

### Port Scanning
**Simple:** An attack technique where someone tries to connect to many different ports on a target to find which services are running. Like trying every door in a building to find unlocked ones.  
**In our project:** The `MaliciousTrafficApp` sends packets to ports 1–100 on the ERP server every 2 seconds. When more than 10 unique ports are detected from one source, 30 risk points are added.

---

### Port Security
**Simple:** A switch feature that limits which devices can connect to a network port and how many devices can use it.  
**In our project:** While NS-3 doesn't simulate port security directly, our Zero-Trust Access Matrix achieves similar protection by controlling which source VLANs can communicate with which destination VLANs.

---

## Q

### Quarantine
**Simple:** Isolating a compromised device from the network so it cannot cause further damage. Like putting a sick patient in isolation.  
**In our project:** When a device's risk score reaches ≥ 70, its network interfaces are disabled using `ipv4->SetDown()`. The device is completely cut off from the network. It can recover automatically when the score decays below 70 (thanks to temporal decay).

---

## R

### Routing
**Simple:** The process of finding the best path for data to travel from source to destination across a network.  
**In our project:** `Ipv4GlobalRoutingHelper::PopulateRoutingTables()` calculates routes for all 58 nodes. When the primary link fails, `RecomputeRoutingTables()` recalculates all routes to use the backup path.  
**If Sir asks about Static vs Dynamic:**
- **Static Routing:** Routes manually configured by admin. Doesn't change automatically. Good for small networks.
- **Dynamic Routing:** Routes calculated automatically by protocols (OSPF, RIP, BGP). Changes when topology changes. Used in our project for self-healing.

---

### Routing Table
**Simple:** A table stored in a router that lists all known network destinations and which interface/next-hop to use to reach them. Like a map that says "to reach Department X, use Door Y."  
**In our project:** When the primary DC link fails, the routing tables are flushed and recomputed. All routes to `10.0.80.0/24` (Data Center) now point through the backup path via `10.0.2.0/24` and Distribution Switch 2.

---

## S

### Subnet / Subnetting
**Simple:** Dividing a large network into smaller sub-networks. Like dividing a big garden into separate plots.  
**In our project:** Each department gets its own /24 subnet:
- Admin: `10.0.10.0/24` (256 addresses)
- CSE: `10.0.20.0/24`
- IT: `10.0.30.0/24`
- Library: `10.0.40.0/24`
- COE: `10.0.50.0/24`
- Hostel: `10.0.60.0/24`
- IoT: `10.0.70.0/24`
- Data Center: `10.0.80.0/24`

---

### Subnet Mask
**Simple:** A number that tells you which part of an IP address is the "network" part and which part is the "host" part.  
**In our project:** We use `255.255.255.0` (/24) for all department subnets. This means the first 3 octets identify the network, and the last octet identifies the device (up to 254 hosts per subnet).

---

## T

### TCP/IP (Transmission Control Protocol / Internet Protocol)
**Simple:** The fundamental set of rules that governs how data is sent and received over the internet. TCP ensures reliable delivery; IP handles addressing and routing.  
**In our project:** All legitimate traffic uses UDP (User Datagram Protocol) for speed, but the Internet stack installed by NS-3's `InternetStackHelper` includes the full TCP/IP suite.

---

### Temporal Decay
**Simple:** A mathematical mechanism that makes old events "fade away" over time. Like how a bruise heals gradually.  
**In our project:** Every 1 second, all risk scores are multiplied by 0.95 (decay factor γ). A score of 100 decays to ~50 in about 14 seconds if no new suspicious activity occurs. This prevents permanent quarantine of innocent devices.  
**Formula:** `R(d, t) = MIN(100, R(d, t-1) × 0.95 + ΔR(d, t))`

---

### Throughput
**Simple:** The actual amount of data successfully transmitted per second. Measured in bits per second (bps, Kbps, Mbps).  
**In our project:** Scenario 4 achieves a total throughput of 25,030 Kbps across all 150 flows.

---

## U

### UDP (User Datagram Protocol)
**Simple:** A communication protocol that sends data without checking if it arrived. Faster than TCP but less reliable. Used for video streaming, gaming, DNS.  
**In our project:** All traffic (legitimate and malicious) uses UDP sockets. The `OnOffHelper` with `ns3::UdpSocketFactory` generates the legitimate campus traffic.

---

## V

### VLAN (Virtual Local Area Network)
**Simple:** A logical grouping of network devices that behave as if they are on the same physical network, even if they are not. Like virtual walls inside a building.  
**In our project:** We have 8 VLANs implemented as separate CSMA segments:

| VLAN Tag | Department | Subnet | Nodes |
|----------|------------|--------|-------|
| 10 | Administration | 10.0.10.0/24 | 4 |
| 20 | CSE | 10.0.20.0/24 | 10 |
| 30 | IT | 10.0.30.0/24 | 10 |
| 40 | Library | 10.0.40.0/24 | 6 |
| 50 | COE | 10.0.50.0/24 | 4 |
| 60 | Hostel | 10.0.60.0/24 | 8 |
| 70 | IoT Lab | 10.0.70.0/24 | 6 |
| 80 | Data Center | 10.0.80.0/24 | 7 |

**If Sir asks:** *"A VLAN is a broadcast domain created by switches. Devices in the same VLAN can communicate directly, but devices in different VLANs need a router. We use 8 VLANs to segment our campus — this limits the blast radius of any attack to a single department."*

---

### VLSM (Variable Length Subnet Masking)
**Simple:** Using different subnet mask sizes for different parts of the network to avoid wasting IP addresses. Some subnets get more addresses, others get fewer.  
**In our project:** Currently we use a uniform /24 mask for all departments. However, in a real deployment, VLSM would be applied:
- CSE/IT (10 nodes): could use /28 (14 usable hosts)
- Admin/COE (4 nodes): could use /29 (6 usable hosts)
- Data Center (7 nodes): could use /28 (14 usable hosts)

---

## Z

### Zero-Trust Architecture (ZTA)
**Simple:** A security model that says "never trust anyone, always verify." Even if a device is already inside the network, it must continuously prove it is legitimate.  
**In our project:** Every single packet forwarded by the Core Router is inspected against the access policy matrix. Even a CSE laptop that was just working fine 10 seconds ago gets checked every time. If its behaviour changes (starts scanning ports), its risk score goes up and it gets quarantined.  
**If Sir asks:** *"Zero-Trust replaces the old castle-and-moat model. Instead of trusting everything inside the perimeter, we verify every request regardless of source. Our implementation applies continuous behavioural monitoring and calculates a real-time risk score for every device."*

---

> **Tip for all 5 members:** Practice saying these definitions out loud before the review. Sir may ask any of you about any term. Everyone should know at least the "Simple" explanation for every term above.
