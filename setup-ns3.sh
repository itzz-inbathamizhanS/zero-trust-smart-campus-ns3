#!/bin/bash
# ============================================================================
#  NS-3 Smart Campus Network — Setup Script
#  -----------------------------------------
#  Installs NS-3 on Ubuntu/WSL and sets up the project.
#
#  Usage (inside WSL terminal):
#    chmod +x setup-ns3.sh
#    ./setup-ns3.sh
#
#  This script will:
#    1. Install required packages (build tools, Python, etc.)
#    2. Download and build NS-3 (version 3.41)
#    3. Copy the simulation files to the ns-3 scratch directory
#    4. Build and verify the simulation
# ============================================================================

set -e  # Exit on any error

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  NS-3 Smart Campus Network — Installation Script       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

NS3_VERSION="3.41"
NS3_DIR="$HOME/ns-allinone-${NS3_VERSION}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ============================================================================
# STEP 1: Install system dependencies
# ============================================================================
echo "[1/6] Installing system dependencies..."

sudo apt-get update -qq
sudo apt-get install -y -qq \
    g++ \
    cmake \
    ninja-build \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-dev \
    pkg-config \
    sqlite3 \
    libsqlite3-dev \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    libxml2-dev \
    libgtk-3-dev \
    gir1.2-goocanvas-2.0 \
    python3-gi \
    python3-gi-cairo \
    gir1.2-gtk-3.0 \
    libgsl-dev \
    libboost-all-dev \
    wget \
    tar \
    unzip \
    2>/dev/null || true

echo "  [OK] System dependencies installed."

# ============================================================================
# STEP 2: Install Python dependencies (for analysis)
# ============================================================================
echo "[2/6] Installing Python dependencies..."

pip3 install --quiet matplotlib numpy 2>/dev/null || \
    pip3 install --quiet --break-system-packages matplotlib numpy 2>/dev/null || true

echo "  [OK] Python dependencies installed."

# ============================================================================
# STEP 3: Download NS-3
# ============================================================================
echo "[3/6] Downloading NS-3 v${NS3_VERSION}..."

if [ -d "$NS3_DIR" ]; then
    echo "  [SKIP] NS-3 directory already exists at $NS3_DIR"
else
    cd "$HOME"
    wget -q "https://www.nsnam.org/releases/ns-allinone-${NS3_VERSION}.tar.bz2" \
         -O "ns-allinone-${NS3_VERSION}.tar.bz2"
    tar xjf "ns-allinone-${NS3_VERSION}.tar.bz2"
    rm -f "ns-allinone-${NS3_VERSION}.tar.bz2"
    echo "  [OK] NS-3 downloaded to $NS3_DIR"
fi

NS3_SRC="$NS3_DIR/ns-${NS3_VERSION}"

# ============================================================================
# STEP 4: Build NS-3
# ============================================================================
echo "[4/6] Building NS-3 (this may take 10-20 minutes)..."

cd "$NS3_SRC"

# Configure with CMake
./ns3 configure --build-profile=optimized --enable-examples --enable-tests \
    2>&1 | tail -5

# Build
./ns3 build 2>&1 | tail -5

echo "  [OK] NS-3 built successfully."

# ============================================================================
# STEP 5: Copy simulation files
# ============================================================================
echo "[5/6] Copying Smart Campus simulation files..."

SCRATCH_DIR="$NS3_SRC/scratch/smart-campus"
mkdir -p "$SCRATCH_DIR"

# Copy the main simulation file
cp "$PROJECT_DIR/scratch/smart-campus/smart-campus-network.cc" \
   "$SCRATCH_DIR/smart-campus-network.cc"

echo "  [OK] Simulation files copied to $SCRATCH_DIR"

# ============================================================================
# STEP 6: Build and verify the simulation
# ============================================================================
echo "[6/6] Building the Smart Campus simulation..."

cd "$NS3_SRC"
./ns3 build 2>&1 | tail -5

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║               INSTALLATION COMPLETE!                    ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                        ║"
echo "║  NS-3 Location: $NS3_SRC"
echo "║                                                        ║"
echo "║  To run the simulation:                                ║"
echo "║    cd $NS3_SRC"
echo "║    ./ns3 run 'smart-campus --scenario=1'  # Normal     ║"
echo "║    ./ns3 run 'smart-campus --scenario=2'  # Attack     ║"
echo "║    ./ns3 run 'smart-campus --scenario=3'  # Self-Heal  ║"
echo "║    ./ns3 run 'smart-campus --scenario=4'  # Combined   ║"
echo "║                                                        ║"
echo "║  To analyse results:                                   ║"
echo "║    python3 $PROJECT_DIR/analysis/analyze-results.py    ║"
echo "║                                                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
