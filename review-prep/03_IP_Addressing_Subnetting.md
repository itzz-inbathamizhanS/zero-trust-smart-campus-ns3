# 🔢 IP Addressing & Subnetting — Review 2 (5 Marks)

> **Rubric Criteria:** Efficient VLSM/Subnet design

---

## What is IP Addressing?

**Simple:** Every device on a network needs a unique address so data can find it. An IP address is like a postal address for your computer. IPv4 addresses are written as 4 numbers separated by dots: `10.0.20.2`

Each number (called an **octet**) ranges from 0 to 255.

---

## What is Subnetting?

**Simple:** Subnetting is dividing one big network into smaller pieces. Like dividing a large plot of land into individual house plots.

**Example:** Instead of putting all 58 devices on one network `10.0.0.0`, we divide it into 8 smaller subnets — one per department.

---

## Our Complete IP Addressing Scheme

### Class A Private Address: `10.0.0.0`

We chose `10.0.0.0` because:
- It's a **private IP range** (not routable on the internet) — safe for internal campus use
- It gives us a massive address space (over 16 million addresses)
- The second octet (`.0.`) is unused, the third octet (`.X.`) identifies each department

### Master IP Table

| Subnet | Department | Network Address | Subnet Mask | Gateway (Router) | Usable Range | Nodes |
|--------|------------|----------------|-------------|-------------------|-------------|-------|
| **Backbone** | Internet ↔ Router | `10.0.1.0` | `/24` (255.255.255.0) | `10.0.1.1` (Router) | `10.0.1.1 – 10.0.1.254` | 2 |
| **Backup Link** | Router ↔ Backup Switch | `10.0.2.0` | `/24` | `10.0.2.1` (Router) | `10.0.2.1 – 10.0.2.254` | 2 |
| **VLAN 10** | Administration | `10.0.10.0` | `/24` | `10.0.10.1` | `10.0.10.2 – 10.0.10.254` | 4 |
| **VLAN 20** | CSE Department | `10.0.20.0` | `/24` | `10.0.20.1` | `10.0.20.2 – 10.0.20.254` | 10 |
| **VLAN 30** | IT Department | `10.0.30.0` | `/24` | `10.0.30.1` | `10.0.30.2 – 10.0.30.254` | 10 |
| **VLAN 40** | Library | `10.0.40.0` | `/24` | `10.0.40.1` | `10.0.40.2 – 10.0.40.254` | 6 |
| **VLAN 50** | COE | `10.0.50.0` | `/24` | `10.0.50.1` | `10.0.50.2 – 10.0.50.254` | 4 |
| **VLAN 60** | Hostel | `10.0.60.0` | `/24` | `10.0.60.1` | `10.0.60.2 – 10.0.60.254` | 8 |
| **VLAN 70** | IoT Lab | `10.0.70.0` | `/24` | `10.0.70.1` | `10.0.70.2 – 10.0.70.254` | 6 |
| **VLAN 80** | Data Center (Primary) | `10.0.80.0` | `/24` | `10.0.80.1` | `10.0.80.2 – 10.0.80.254` | 7 |
| **VLAN 82** | Data Center (Backup) | `10.0.82.0` | `/24` | `10.0.82.1` | `10.0.82.2 – 10.0.82.254` | 7 |

---

## Key Device IP Addresses (Memorize These!)

| Device | IP Address | Department |
|--------|-----------|------------|
| Internet Server | `10.0.1.1` | Backbone |
| Core Router (backbone) | `10.0.1.2` | Backbone |
| **Attacker (CSE student)** | **`10.0.20.2`** | CSE VLAN |
| Admin PC-1 | `10.0.10.2` | Admin VLAN |
| COE Research-1 | `10.0.50.2` | COE VLAN |
| **ERP Server** | **`10.0.80.2`** | Data Center |
| DNS Server | `10.0.80.5` | Data Center |
| Web Server | `10.0.80.6` | Data Center |

> **Important:** The router's IP on each VLAN is always `.1` (first usable address). Department nodes start from `.2`.

---

## How Subnetting Works (Step by Step)

### Understanding `/24` (255.255.255.0)

```
IP Address:    10  .  0  .  20  .  2
In Binary:     00001010.00000000.00010100.00000010

Subnet Mask:   255.255.255.0
In Binary:     11111111.11111111.11111111.00000000
                ←— Network Part (24 bits) —→←Host→

Network ID:    10.0.20.0    (first address — identifies the subnet)
Broadcast:     10.0.20.255  (last address — reaches all devices)
Usable Range:  10.0.20.1 to 10.0.20.254 (254 usable addresses)
```

### How to Identify Department from IP

**Just look at the 3rd octet:**
- `10.0.10.x` → 10 → Admin
- `10.0.20.x` → 20 → CSE
- `10.0.30.x` → 30 → IT
- `10.0.40.x` → 40 → Library
- `10.0.50.x` → 50 → COE
- `10.0.60.x` → 60 → Hostel
- `10.0.70.x` → 70 → IoT Lab
- `10.0.80.x` → 80 → Data Center

This is exactly how our code identifies VLANs! Look at this from the C++ source:
```cpp
uint8_t third = (ip >> 8) & 0xFF;  // Extract 3rd octet
switch (third) {
    case 10: return "ADMIN";
    case 20: return "CSE";
    case 30: return "IT";
    // ... and so on
}
```

---

## VLSM — What It Is and How It Applies

### What is VLSM?
**Simple:** VLSM (Variable Length Subnet Masking) means using different subnet sizes for different needs. Instead of giving every department 254 addresses, you give bigger subnets to bigger departments and smaller subnets to smaller ones.

### Current Design (Uniform /24):
Every department gets 254 usable addresses. This wastes addresses for small departments.

### VLSM Optimized Design (If Sir Asks):

| Department | Actual Nodes | VLSM Mask | Usable IPs | Waste |
|------------|-------------|-----------|-----------|-------|
| CSE | 10 | `/28` (255.255.255.240) | 14 | 4 wasted |
| IT | 10 | `/28` | 14 | 4 wasted |
| Hostel | 8 | `/28` | 14 | 6 wasted |
| Data Center | 7 | `/28` | 14 | 7 wasted |
| Library | 6 | `/29` (255.255.255.248) | 6 | 0 wasted |
| IoT Lab | 6 | `/29` | 6 | 0 wasted |
| Admin | 4 | `/29` | 6 | 2 wasted |
| COE | 4 | `/29` | 6 | 2 wasted |
| Backbone | 2 | `/30` (255.255.255.252) | 2 | 0 wasted |
| Backup Link | 2 | `/30` | 2 | 0 wasted |

**If Sir asks "Why did you use /24 instead of VLSM?"**
> *"We used a uniform /24 addressing scheme in the NS-3 simulation for clarity and simplicity, as NS-3's Ipv4AddressHelper works most naturally with /24 subnets. However, for a real campus deployment, we would apply VLSM to optimize address utilization. For example, the CSE department with 10 nodes only needs a /28 (14 hosts), saving 240 addresses per subnet."*

---

## How Addressing Enables Security

The IP addressing scheme is critical to our security design because:

1. **VLAN Identification:** The router identifies which department a packet belongs to by reading the 3rd octet of the IP address
2. **Policy Enforcement:** The Zero-Trust Access Matrix uses VLAN names (derived from IPs) to decide allow/deny
3. **Risk Attribution:** When a policy violation occurs, the risk score is attributed to the source IP address
4. **Quarantine:** The quarantine controller maps IP addresses to specific NS-3 nodes, so it can disable the right device's interfaces

---

## Questions Sir May Ask

**Q: "What IP addressing scheme did you use?"**
> *"We used a Class A private address space (10.0.0.0) with /24 subnets for each department. The third octet identifies the department — 10 for Admin, 20 for CSE, 30 for IT, and so on up to 80 for Data Center. Each subnet provides 254 usable host addresses."*

**Q: "What is the subnet mask?"**
> *"255.255.255.0, also written as /24. This means the first 24 bits identify the network, and the last 8 bits identify the host. Each subnet supports up to 254 usable addresses."*

**Q: "Why did you choose 10.0.0.0?"**
> *"10.0.0.0/8 is a private IP range defined in RFC 1918. It's not routable on the public internet, so it's safe for internal campus use. It also gives us a very large address space — over 16 million addresses — which makes subnet planning flexible."*

**Q: "What is VLSM? Did you use it?"**
> *"VLSM stands for Variable Length Subnet Masking. It allows different subnets to have different sizes, reducing IP address waste. In our NS-3 simulation, we used uniform /24 subnets for simplicity. In a real deployment, we would use VLSM — for example, /28 for CSE (14 hosts) and /29 for Admin (6 hosts)."*

**Q: "What is the IP of the attacker?"**
> *"`10.0.20.2` — the first CSE student node in VLAN 20."*

**Q: "How does the router know which department a packet is from?"**
> *"By extracting the third octet of the source IP address. If a packet comes from 10.0.20.x, the router knows it's from the CSE department. This is implemented in the `VlanNameFromIp()` function in our C++ code."*
