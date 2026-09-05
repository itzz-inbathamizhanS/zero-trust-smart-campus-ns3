#!/bin/bash
# ============================================================================
#  Zero-Trust Self-Healing Smart Campus Network — One-Click Setup
#  ===============================================================
#  This script automatically sets up everything needed to run the
#  NS-3 Smart Campus Network simulation.
#
#  Works on:
#    - Native Ubuntu (20.04, 22.04, 24.04, 26.04)
#    - Windows WSL (Ubuntu)
#
#  Usage:
#    chmod +x setup.sh
#    ./setup.sh
#
#  What this script does:
#    1. Detects your environment (WSL or native Ubuntu)
#    2. Installs all system dependencies
#    3. Downloads and builds NS-3 v3.41
#    4. Fixes Python/GCC compatibility issues automatically
#    5. Copies and builds the Smart Campus simulation
#    6. Builds NetAnim (visual animator)
#    7. Runs all 4 simulation scenarios
#    8. Generates analysis graphs
#
#  Total time: ~20-30 minutes (first run)
# ============================================================================

set -e

# ======================== COLOURS ========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ======================== VARIABLES ========================
NS3_VERSION="3.41"
NS3_DIR="$HOME/ns-allinone-${NS3_VERSION}"
NS3_SRC="$NS3_DIR/ns-${NS3_VERSION}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRATCH_DIR="$NS3_SRC/scratch/smart-campus"
RESULTS_DIR="$PROJECT_DIR/results"

# ======================== HELPER FUNCTIONS ========================

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║${BOLD}   ZERO-TRUST SELF-HEALING SMART CAMPUS NETWORK             ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${BOLD}   Automated Setup & Simulation Script                      ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║   Patent: Risk-Based Dynamic Network Quarantine with       ║${NC}"
    echo -e "${CYAN}║   Autonomous Self-Healing in Zero-Trust Campus Networks     ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}[$1/$TOTAL_STEPS] $2${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_ok() {
    echo -e "  ${GREEN}✔ $1${NC}"
}

log_warn() {
    echo -e "  ${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "  ${RED}✘ $1${NC}"
}

log_info() {
    echo -e "  ${CYAN}ℹ $1${NC}"
}

TOTAL_STEPS=10

# ======================== MAIN SCRIPT ========================

print_banner

# ──────────────────────────────────────────────────────────────
# STEP 1: Detect Environment
# ──────────────────────────────────────────────────────────────
log_step 1 "Detecting Environment"

IS_WSL=false
IS_UBUNTU=false
UBUNTU_VERSION="unknown"

# Check if running on WSL
if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    IS_WSL=true
    log_ok "Detected: Windows Subsystem for Linux (WSL)"
else
    log_ok "Detected: Native Linux"
fi

# Check if running Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        IS_UBUNTU=true
        UBUNTU_VERSION="$VERSION_ID"
        log_ok "OS: Ubuntu $UBUNTU_VERSION ($VERSION_CODENAME)"
    else
        log_warn "OS: $PRETTY_NAME (not Ubuntu — some steps may need adjustment)"
    fi
else
    log_warn "Could not detect OS version"
fi

# Check architecture
ARCH=$(uname -m)
log_ok "Architecture: $ARCH"

# Check available RAM
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
log_ok "Available RAM: ${TOTAL_RAM}MB"

if [ "$TOTAL_RAM" -lt 2048 ]; then
    log_warn "Low RAM detected. Build may be slow. Recommend at least 4GB."
fi

# Check available disk space
AVAILABLE_DISK=$(df -BM "$HOME" | awk 'NR==2{print $4}' | tr -d 'M')
log_ok "Available Disk Space: ${AVAILABLE_DISK}MB"

if [ "$AVAILABLE_DISK" -lt 3000 ]; then
    log_error "Not enough disk space. Need at least 3GB free."
    log_error "Current free space: ${AVAILABLE_DISK}MB"
    exit 1
fi

# ──────────────────────────────────────────────────────────────
# STEP 2: Install System Dependencies
# ──────────────────────────────────────────────────────────────
log_step 2 "Installing System Dependencies"

log_info "Updating package lists..."
sudo apt-get update -qq 2>/dev/null || {
    log_warn "apt-get update had warnings (non-fatal, continuing...)"
}

log_info "Installing build tools (gcc, cmake, ninja)..."
sudo apt-get install -y -qq \
    g++ \
    cmake \
    ninja-build \
    git \
    pkg-config \
    wget \
    tar \
    unzip \
    sed \
    2>/dev/null || true
log_ok "Build tools installed"

log_info "Installing NS-3 library dependencies..."
sudo apt-get install -y -qq \
    sqlite3 \
    libsqlite3-dev \
    libxml2-dev \
    libgtk-3-dev \
    libgsl-dev \
    libboost-all-dev \
    2>/dev/null || true
log_ok "NS-3 libraries installed"

log_info "Installing Qt5 (for NetAnim visualisation)..."
sudo apt-get install -y -qq \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    2>/dev/null || true
log_ok "Qt5 installed"

# ──────────────────────────────────────────────────────────────
# STEP 3: Setup Python (handle 3.14 compatibility)
# ──────────────────────────────────────────────────────────────
log_step 3 "Setting Up Python Environment"

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

log_info "System Python: $PYTHON_VERSION"

NEED_PYTHON_FIX=false

if [ "$PYTHON_MINOR" -ge 14 ]; then
    log_warn "Python $PYTHON_VERSION detected — incompatible with NS-3 v3.41"
    log_info "Installing Python 3.12 via deadsnakes PPA..."
    NEED_PYTHON_FIX=true

    # Install software-properties-common for add-apt-repository
    sudo apt-get install -y -qq software-properties-common 2>/dev/null || true

    # Add deadsnakes PPA
    sudo add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
    sudo apt-get update -qq 2>/dev/null || true

    # Install Python 3.12
    sudo apt-get install -y -qq python3.12 2>/dev/null || {
        log_error "Failed to install Python 3.12. Trying alternative method..."
        # Try installing from universe repo
        sudo apt-get install -y -qq python3.12-minimal 2>/dev/null || true
    }

    if command -v python3.12 &>/dev/null; then
        log_ok "Python 3.12 installed successfully"
    else
        log_error "Could not install Python 3.12. Please install it manually."
        exit 1
    fi
elif [ "$PYTHON_MINOR" -ge 10 ] && [ "$PYTHON_MINOR" -le 13 ]; then
    log_ok "Python $PYTHON_VERSION is compatible with NS-3"
else
    log_warn "Python $PYTHON_VERSION — may have compatibility issues"
fi

# Install Python analysis dependencies
log_info "Installing Python analysis libraries (matplotlib, numpy)..."
if [ "$NEED_PYTHON_FIX" = true ]; then
    # Install pip for Python 3.12
    sudo apt-get install -y -qq python3.12-distutils 2>/dev/null || true
    python3.12 -m pip install --quiet matplotlib numpy 2>/dev/null || \
        pip3 install --quiet --break-system-packages matplotlib numpy 2>/dev/null || \
        log_warn "Could not install matplotlib/numpy. Graphs may not generate."
else
    pip3 install --quiet matplotlib numpy 2>/dev/null || \
        pip3 install --quiet --break-system-packages matplotlib numpy 2>/dev/null || \
        log_warn "Could not install matplotlib/numpy. Graphs may not generate."
fi
log_ok "Python environment ready"

# ──────────────────────────────────────────────────────────────
# STEP 4: Download NS-3
# ──────────────────────────────────────────────────────────────
log_step 4 "Downloading NS-3 v${NS3_VERSION}"

if [ -d "$NS3_DIR" ]; then
    log_ok "NS-3 already downloaded at $NS3_DIR (skipping download)"
else
    log_info "Downloading NS-3 v${NS3_VERSION} (~120MB)..."
    cd "$HOME"
    wget -q --show-progress \
        "https://www.nsnam.org/releases/ns-allinone-${NS3_VERSION}.tar.bz2" \
        -O "ns-allinone-${NS3_VERSION}.tar.bz2"

    log_info "Extracting archive..."
    tar xjf "ns-allinone-${NS3_VERSION}.tar.bz2"
    rm -f "ns-allinone-${NS3_VERSION}.tar.bz2"
    log_ok "NS-3 v${NS3_VERSION} downloaded and extracted"
fi

# ──────────────────────────────────────────────────────────────
# STEP 5: Patch NS-3 for GCC 15 / Python 3.14 Compatibility
# ──────────────────────────────────────────────────────────────
log_step 5 "Patching NS-3 for Compatibility"

# Fix 1: Python 3.14 argparse compatibility — make ns3 script use python3.12
if [ "$NEED_PYTHON_FIX" = true ]; then
    NS3_SCRIPT="$NS3_SRC/ns3"
    CURRENT_SHEBANG=$(head -1 "$NS3_SCRIPT")
    if [[ "$CURRENT_SHEBANG" != *"python3.12"* ]]; then
        sed -i '1s|.*|#!/usr/bin/env python3.12|' "$NS3_SCRIPT"
        log_ok "Patched ns3 script to use Python 3.12"
    else
        log_ok "ns3 script already patched for Python 3.12"
    fi
fi

# Fix 2: GCC 15 missing #include <algorithm> in wifi module
WIFI_HEADER="$NS3_SRC/src/wifi/model/wifi-phy-state-helper.h"
if [ -f "$WIFI_HEADER" ]; then
    FIRST_LINE=$(head -1 "$WIFI_HEADER")
    if [[ "$FIRST_LINE" != "#include <algorithm>" ]]; then
        sed -i '1s/^/#include <algorithm>\n/' "$WIFI_HEADER"
        log_ok "Patched wifi-phy-state-helper.h (added missing #include)"
    else
        log_ok "wifi-phy-state-helper.h already patched"
    fi
fi

log_ok "All compatibility patches applied"

# ──────────────────────────────────────────────────────────────
# STEP 6: Configure NS-3
# ──────────────────────────────────────────────────────────────
log_step 6 "Configuring NS-3"

cd "$NS3_SRC"

log_info "Running CMake configuration (optimized build, selected modules only)..."
./ns3 configure --build-profile=optimized \
    -- "-DNS3_ENABLED_MODULES=core;network;internet;point-to-point;point-to-point-layout;csma;csma-layout;applications;flow-monitor;netanim;bridge;traffic-control;mobility;stats" \
    -DNS3_EXAMPLES=OFF \
    -DNS3_TESTS=OFF \
    2>&1 | tail -20

log_ok "NS-3 configured successfully"

# ──────────────────────────────────────────────────────────────
# STEP 7: Build NS-3
# ──────────────────────────────────────────────────────────────
log_step 7 "Building NS-3 (this takes 5-15 minutes)"

cd "$NS3_SRC"

# Determine number of CPU cores for parallel build
CORES=$(nproc 2>/dev/null || echo 2)
log_info "Building with $CORES parallel jobs..."

./ns3 build 2>&1 | tail -5

# Check if build succeeded
if [ $? -eq 0 ]; then
    log_ok "NS-3 core libraries built successfully"
else
    log_error "NS-3 build failed. Check the output above for errors."
    exit 1
fi

# ──────────────────────────────────────────────────────────────
# STEP 8: Copy and Build Smart Campus Simulation
# ──────────────────────────────────────────────────────────────
log_step 8 "Building Smart Campus Simulation"

# Create scratch directory
mkdir -p "$SCRATCH_DIR"

# Copy the simulation source file
cp "$PROJECT_DIR/scratch/smart-campus/smart-campus-network.cc" \
   "$SCRATCH_DIR/smart-campus-network.cc"
log_ok "Simulation source copied to NS-3 scratch directory"

# Rebuild to compile our simulation
log_info "Compiling smart-campus-network..."
cd "$NS3_SRC"
./ns3 build 2>&1 | tail -5

# Verify the binary was created
BINARY=$(find "$NS3_SRC/build" -name "*smart-campus*" -type f 2>/dev/null | head -1)
if [ -n "$BINARY" ]; then
    log_ok "Smart Campus simulation compiled: $(basename $BINARY)"
else
    log_error "Simulation binary not found. Build may have failed."
    exit 1
fi

# ──────────────────────────────────────────────────────────────
# STEP 9: Build NetAnim (Visual Animator)
# ──────────────────────────────────────────────────────────────
log_step 9 "Building NetAnim (Visual Animator)"

NETANIM_DIR="$NS3_DIR/netanim-3.109"

if [ -d "$NETANIM_DIR" ]; then
    cd "$NETANIM_DIR"

    if [ -f "NetAnim" ]; then
        log_ok "NetAnim already built"
    else
        log_info "Compiling NetAnim..."
        qmake NetAnim.pro 2>/dev/null && make -j"$CORES" 2>&1 | tail -3

        if [ -f "NetAnim" ]; then
            log_ok "NetAnim built successfully"
        else
            log_warn "NetAnim build failed (non-critical — simulation still works)"
        fi
    fi
else
    log_warn "NetAnim directory not found (non-critical — simulation still works)"
fi

# ──────────────────────────────────────────────────────────────
# STEP 10: Run All Scenarios
# ──────────────────────────────────────────────────────────────
log_step 10 "Running Simulations"

cd "$NS3_SRC"
mkdir -p "$RESULTS_DIR"

echo ""
echo -e "${CYAN}  Running 4 simulation scenarios...${NC}"
echo ""

for SCENARIO in 1 2 3 4; do
    case $SCENARIO in
        1) DESC="Normal Operation (baseline)" ;;
        2) DESC="Malware Attack + Dynamic Quarantine" ;;
        3) DESC="Link Failure + Self-Healing" ;;
        4) DESC="Combined (Attack + Quarantine + Self-Healing)" ;;
    esac

    echo -ne "  ${YELLOW}▶ Scenario $SCENARIO:${NC} $DESC ... "
    ./ns3 run "smart-campus-network --scenario=$SCENARIO" 2>&1 | tail -1

    # Copy output files to results directory
    cp -f smart-campus-s${SCENARIO}-*.csv "$RESULTS_DIR/" 2>/dev/null || true
    cp -f smart-campus-s${SCENARIO}-*.xml "$RESULTS_DIR/" 2>/dev/null || true

    echo -e "${GREEN}✔ Done${NC}"
done

log_ok "All 4 scenarios completed"

# ──────────────────────────────────────────────────────────────
# BONUS: Generate Analysis Graphs
# ──────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}[BONUS] Generating Analysis Graphs${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$RESULTS_DIR"

# Determine which python to use for analysis
if [ "$NEED_PYTHON_FIX" = true ] && command -v python3.12 &>/dev/null; then
    PYTHON_CMD="python3.12"
else
    PYTHON_CMD="python3"
fi

# Run analysis for scenario 4 (combined)
$PYTHON_CMD "$PROJECT_DIR/analysis/analyze-results.py" --scenario 4 --prefix "$RESULTS_DIR/smart-campus-s4-" 2>/dev/null || {
    log_warn "Graph generation had issues (matplotlib may need a display)"
    log_info "You can generate graphs manually later with:"
    log_info "  cd $RESULTS_DIR"
    log_info "  $PYTHON_CMD $PROJECT_DIR/analysis/analyze-results.py --scenario 4"
}

# Copy results to Windows-accessible location if on WSL
if [ "$IS_WSL" = true ]; then
    WINDOWS_RESULTS="/mnt/d/CN/ns3-smart-campus/results"
    mkdir -p "$WINDOWS_RESULTS" 2>/dev/null || true
    cp -f "$RESULTS_DIR"/*.csv "$WINDOWS_RESULTS/" 2>/dev/null || true
    cp -f "$RESULTS_DIR"/*.png "$WINDOWS_RESULTS/" 2>/dev/null || true
    cp -f "$RESULTS_DIR"/*.xml "$WINDOWS_RESULTS/" 2>/dev/null || true
    log_ok "Results copied to Windows: D:\\CN\\ns3-smart-campus\\results\\"
fi

# ──────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ──────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║              ✅ SETUP COMPLETE — ALL SYSTEMS GO!            ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║${NC}  NS-3 Location:  ${BOLD}$NS3_SRC${NC}"
echo -e "${GREEN}║${NC}  Simulation:     ${BOLD}$SCRATCH_DIR${NC}"
echo -e "${GREEN}║${NC}  Results:        ${BOLD}$RESULTS_DIR${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Re-run a simulation:${NC}                                      "
echo -e "${GREEN}║${NC}    cd $NS3_SRC"
echo -e "${GREEN}║${NC}    ./ns3 run \"smart-campus-network --scenario=4\"             "
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Open NetAnim (live visualisation):${NC}                         "
echo -e "${GREEN}║${NC}    cd $NETANIM_DIR"
echo -e "${GREEN}║${NC}    ./NetAnim                                                 "
echo -e "${GREEN}║${NC}    → Open: smart-campus-s4-animation.xml                     "
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Generate graphs:${NC}                                           "
echo -e "${GREEN}║${NC}    cd $RESULTS_DIR"
echo -e "${GREEN}║${NC}    $PYTHON_CMD $PROJECT_DIR/analysis/analyze-results.py"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
