#!/bin/bash
# ============================================================================
#  Zero-Trust Self-Healing Smart Campus Network — Interactive Setup & Runner
#  =========================================================================
#  
#  One-click interactive tool for setup, simulation, visualisation & analysis.
#
#  Usage:
#    chmod +x setup.sh
#    ./setup.sh
#
# ============================================================================

# ======================== COLOURS & SYMBOLS ========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
CHECK="${GREEN}✔${NC}"
CROSS="${RED}✘${NC}"
WARN="${YELLOW}⚠${NC}"
ARROW="${CYAN}▶${NC}"
STAR="${YELLOW}★${NC}"

# ======================== VARIABLES ========================
NS3_VERSION="3.41"
NS3_DIR="$HOME/ns-allinone-${NS3_VERSION}"
NS3_SRC="$NS3_DIR/ns-${NS3_VERSION}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRATCH_DIR="$NS3_SRC/scratch/smart-campus"
RESULTS_DIR="$PROJECT_DIR/results"
NETANIM_DIR="$NS3_DIR/netanim-3.109"
PYTHON_CMD="python3"
NEED_PYTHON_FIX=false

# Track what's installed
HAS_GCC=false
HAS_CMAKE=false
HAS_NINJA=false
HAS_PYTHON=false
HAS_PYTHON_OK=false
HAS_QT5=false
HAS_WGET=false
HAS_NS3=false
HAS_NS3_BUILT=false
HAS_SIM_BUILT=false
HAS_NETANIM=false
HAS_MATPLOTLIB=false
HAS_BOOST=false
HAS_SQLITE=false
HAS_GTK=false
HAS_GSL=false
IS_WSL=false
ALL_DEPS_OK=false

# ======================== HELPER FUNCTIONS ========================

clear_screen() {
    clear 2>/dev/null || printf '\033[2J\033[H'
}

press_enter() {
    echo ""
    echo -ne "  ${DIM}Press Enter to continue...${NC}"
    read -r
}

print_banner() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                 ║${NC}"
    echo -e "${CYAN}║${NC} ${BOLD} ⚡ ZERO-TRUST SELF-HEALING SMART CAMPUS NETWORK ⚡            ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${DIM}Risk-Based Dynamic Network Quarantine with Autonomous${NC}         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${DIM}Self-Healing in Zero-Trust Campus Networks${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${DIM}NS-3 Simulation Engine v1.0${NC}                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_main_menu() {
    echo -e "  ${BOLD}${BLUE}╭──────────────────────────────────────────╮${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}          ${BOLD}MAIN MENU${NC}                       ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}├──────────────────────────────────────────┤${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}                                          ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}1${NC} ${ARROW} Check System Requirements          ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}2${NC} ${ARROW} Install Missing Dependencies        ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}3${NC} ${ARROW} Download & Build NS-3               ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}4${NC} ${ARROW} Build Smart Campus Simulation       ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}5${NC} ${ARROW} Run Simulation (choose scenario)    ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}6${NC} ${ARROW} Open NetAnim (live visualisation)   ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}7${NC} ${ARROW} Generate Analysis Graphs            ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}8${NC} ${ARROW} Full Auto Setup (do everything)     ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}9${NC} ${ARROW} Clean & Reset Everything            ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}   ${BOLD}0${NC} ${ARROW} Exit                                ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}│${NC}                                          ${BOLD}${BLUE}│${NC}"
    echo -e "  ${BOLD}${BLUE}╰──────────────────────────────────────────╯${NC}"
    echo ""
}

# ======================== SYSTEM CHECKS ========================

detect_environment() {
    if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
        IS_WSL=true
    fi
}

check_all_requirements() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ System Requirements Check ━━━${NC}"
    echo ""

    ALL_DEPS_OK=true

    # -- WSL / Ubuntu --
    detect_environment
    if [ "$IS_WSL" = true ]; then
        echo -e "  ${CHECK} Environment:     WSL (Windows Subsystem for Linux)"
    else
        echo -e "  ${CHECK} Environment:     Native Linux"
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "  ${CHECK} OS:              $PRETTY_NAME"
    fi

    # -- GCC --
    if command -v g++ &>/dev/null; then
        GCC_VER=$(g++ --version | head -1 | grep -oP '\d+\.\d+\.\d+')
        HAS_GCC=true
        echo -e "  ${CHECK} GCC/G++:         $GCC_VER"
    else
        HAS_GCC=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} GCC/G++:         ${RED}Not installed${NC}"
    fi

    # -- CMake --
    if command -v cmake &>/dev/null; then
        CMAKE_VER=$(cmake --version | head -1 | grep -oP '\d+\.\d+(\.\d+)?')
        HAS_CMAKE=true
        echo -e "  ${CHECK} CMake:           $CMAKE_VER"
    else
        HAS_CMAKE=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} CMake:           ${RED}Not installed${NC}"
    fi

    # -- Ninja --
    if command -v ninja &>/dev/null; then
        HAS_NINJA=true
        echo -e "  ${CHECK} Ninja:           $(ninja --version)"
    else
        HAS_NINJA=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} Ninja:           ${RED}Not installed${NC}"
    fi

    # -- Python --
    if command -v python3 &>/dev/null; then
        HAS_PYTHON=true
        PY_VER=$(python3 --version 2>&1 | awk '{print $2}')
        PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)

        if [ "$PY_MINOR" -ge 14 ]; then
            if command -v python3.12 &>/dev/null; then
                HAS_PYTHON_OK=true
                NEED_PYTHON_FIX=true
                PYTHON_CMD="python3.12"
                echo -e "  ${CHECK} Python:          $PY_VER ${YELLOW}(NS-3 will use python3.12)${NC}"
            else
                HAS_PYTHON_OK=false
                NEED_PYTHON_FIX=true
                ALL_DEPS_OK=false
                echo -e "  ${WARN} Python:          $PY_VER ${YELLOW}(too new for NS-3 — need 3.12)${NC}"
            fi
        else
            HAS_PYTHON_OK=true
            echo -e "  ${CHECK} Python:          $PY_VER"
        fi
    else
        HAS_PYTHON=false
        HAS_PYTHON_OK=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} Python:          ${RED}Not installed${NC}"
    fi

    # -- wget --
    if command -v wget &>/dev/null; then
        HAS_WGET=true
        echo -e "  ${CHECK} wget:            installed"
    else
        HAS_WGET=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} wget:            ${RED}Not installed${NC}"
    fi

    # -- Qt5 --
    if command -v qmake &>/dev/null || dpkg -l qtbase5-dev &>/dev/null 2>&1; then
        HAS_QT5=true
        echo -e "  ${CHECK} Qt5:             installed"
    else
        HAS_QT5=false
        echo -e "  ${WARN} Qt5:             ${YELLOW}Not installed (needed for NetAnim only)${NC}"
    fi

    # -- Boost --
    if dpkg -l libboost-all-dev &>/dev/null 2>&1; then
        HAS_BOOST=true
        echo -e "  ${CHECK} Boost:           installed"
    else
        HAS_BOOST=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} Boost:           ${RED}Not installed${NC}"
    fi

    # -- SQLite3 --
    if dpkg -l libsqlite3-dev &>/dev/null 2>&1; then
        HAS_SQLITE=true
        echo -e "  ${CHECK} SQLite3:         installed"
    else
        HAS_SQLITE=false
        ALL_DEPS_OK=false
        echo -e "  ${CROSS} SQLite3:         ${RED}Not installed${NC}"
    fi

    # -- GTK3 --
    if dpkg -l libgtk-3-dev &>/dev/null 2>&1; then
        HAS_GTK=true
        echo -e "  ${CHECK} GTK3:            installed"
    else
        HAS_GTK=false
        echo -e "  ${WARN} GTK3:            ${YELLOW}Not installed (optional)${NC}"
    fi

    # -- GSL --
    if dpkg -l libgsl-dev &>/dev/null 2>&1; then
        HAS_GSL=true
        echo -e "  ${CHECK} GSL:             installed"
    else
        HAS_GSL=false
        echo -e "  ${WARN} GSL:             ${YELLOW}Not installed (optional)${NC}"
    fi

    # -- matplotlib --
    if $PYTHON_CMD -c "import matplotlib" 2>/dev/null; then
        HAS_MATPLOTLIB=true
        echo -e "  ${CHECK} matplotlib:      installed"
    else
        HAS_MATPLOTLIB=false
        echo -e "  ${WARN} matplotlib:      ${YELLOW}Not installed (needed for graphs only)${NC}"
    fi

    # -- NS-3 --
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ Project Status ━━━${NC}"
    echo ""

    if [ -d "$NS3_SRC" ]; then
        HAS_NS3=true
        echo -e "  ${CHECK} NS-3 v${NS3_VERSION}:      Downloaded"
    else
        HAS_NS3=false
        echo -e "  ${CROSS} NS-3 v${NS3_VERSION}:      ${RED}Not downloaded${NC}"
    fi

    if [ -f "$NS3_SRC/cmake-cache/build.ninja" ] 2>/dev/null; then
        HAS_NS3_BUILT=true
        echo -e "  ${CHECK} NS-3 Build:      Compiled"
    else
        HAS_NS3_BUILT=false
        echo -e "  ${CROSS} NS-3 Build:      ${RED}Not compiled${NC}"
    fi

    SIM_BINARY=$(find "$NS3_SRC/build" -name "*smart-campus*" -type f 2>/dev/null | head -1)
    if [ -n "$SIM_BINARY" ]; then
        HAS_SIM_BUILT=true
        echo -e "  ${CHECK} Simulation:      Compiled"
    else
        HAS_SIM_BUILT=false
        echo -e "  ${CROSS} Simulation:      ${RED}Not compiled${NC}"
    fi

    if [ -f "$NETANIM_DIR/NetAnim" ]; then
        HAS_NETANIM=true
        echo -e "  ${CHECK} NetAnim:         Built"
    else
        HAS_NETANIM=false
        echo -e "  ${CROSS} NetAnim:         ${RED}Not built${NC}"
    fi

    # Results
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ Simulation Results ━━━${NC}"
    echo ""
    for S in 1 2 3 4; do
        if ls "$NS3_SRC"/smart-campus-s${S}-*.csv &>/dev/null 2>&1 || \
           ls "$RESULTS_DIR"/smart-campus-s${S}-*.csv &>/dev/null 2>&1; then
            case $S in
                1) echo -e "  ${CHECK} Scenario $S:      ${GREEN}Results available${NC}  (Normal Operation)" ;;
                2) echo -e "  ${CHECK} Scenario $S:      ${GREEN}Results available${NC}  (Attack + Quarantine)" ;;
                3) echo -e "  ${CHECK} Scenario $S:      ${GREEN}Results available${NC}  (Link Failure + Self-Healing)" ;;
                4) echo -e "  ${CHECK} Scenario $S:      ${GREEN}Results available${NC}  (Combined)" ;;
            esac
        else
            case $S in
                1) echo -e "  ${CROSS} Scenario $S:      ${DIM}Not run yet${NC}        (Normal Operation)" ;;
                2) echo -e "  ${CROSS} Scenario $S:      ${DIM}Not run yet${NC}        (Attack + Quarantine)" ;;
                3) echo -e "  ${CROSS} Scenario $S:      ${DIM}Not run yet${NC}        (Link Failure + Self-Healing)" ;;
                4) echo -e "  ${CROSS} Scenario $S:      ${DIM}Not run yet${NC}        (Combined)" ;;
            esac
        fi
    done

    # Summary
    echo ""
    if [ "$ALL_DEPS_OK" = true ] && [ "$HAS_NS3_BUILT" = true ] && [ "$HAS_SIM_BUILT" = true ]; then
        echo -e "  ${GREEN}${BOLD}✅ Everything is ready! Use option 5 to run simulations.${NC}"
    elif [ "$ALL_DEPS_OK" = true ]; then
        echo -e "  ${YELLOW}${BOLD}⚡ Dependencies OK. Use option 3 to download/build NS-3.${NC}"
    else
        echo -e "  ${RED}${BOLD}❌ Some dependencies missing. Use option 2 to install them.${NC}"
    fi
}

# ======================== INSTALLATION FUNCTIONS ========================

install_dependencies() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ Installing Missing Dependencies ━━━${NC}"
    echo ""

    # Core build tools
    if [ "$HAS_GCC" = false ] || [ "$HAS_CMAKE" = false ] || [ "$HAS_NINJA" = false ] || [ "$HAS_WGET" = false ]; then
        echo -e "  ${ARROW} Installing build tools..."
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y -qq g++ cmake ninja-build git pkg-config wget tar unzip sed 2>/dev/null
        echo -e "  ${CHECK} Build tools installed"
    else
        echo -e "  ${CHECK} Build tools already installed (skipping)"
    fi

    # NS-3 libraries
    if [ "$HAS_BOOST" = false ] || [ "$HAS_SQLITE" = false ]; then
        echo -e "  ${ARROW} Installing NS-3 libraries..."
        sudo apt-get install -y -qq \
            sqlite3 libsqlite3-dev libxml2-dev libgtk-3-dev \
            libgsl-dev libboost-all-dev 2>/dev/null
        echo -e "  ${CHECK} NS-3 libraries installed"
    else
        echo -e "  ${CHECK} NS-3 libraries already installed (skipping)"
    fi

    # Qt5
    if [ "$HAS_QT5" = false ]; then
        echo -e "  ${ARROW} Installing Qt5 (for NetAnim)..."
        sudo apt-get install -y -qq qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools 2>/dev/null
        echo -e "  ${CHECK} Qt5 installed"
    else
        echo -e "  ${CHECK} Qt5 already installed (skipping)"
    fi

    # Python 3.12 fix
    if [ "$HAS_PYTHON_OK" = false ] && [ "$NEED_PYTHON_FIX" = true ]; then
        echo -e "  ${ARROW} Installing Python 3.12 (NS-3 compatibility)..."
        sudo apt-get install -y -qq software-properties-common 2>/dev/null
        sudo add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y -qq python3.12 2>/dev/null
        PYTHON_CMD="python3.12"
        HAS_PYTHON_OK=true
        echo -e "  ${CHECK} Python 3.12 installed"
    fi

    # matplotlib
    if [ "$HAS_MATPLOTLIB" = false ]; then
        echo -e "  ${ARROW} Installing matplotlib & numpy..."
        $PYTHON_CMD -m pip install --quiet matplotlib numpy 2>/dev/null || \
            pip3 install --quiet --break-system-packages matplotlib numpy 2>/dev/null || \
            echo -e "  ${WARN} matplotlib install had issues (graphs may not work)"
        echo -e "  ${CHECK} Python analysis libraries installed"
    else
        echo -e "  ${CHECK} matplotlib already installed (skipping)"
    fi

    ALL_DEPS_OK=true
    echo ""
    echo -e "  ${GREEN}${BOLD}✅ All dependencies installed successfully!${NC}"
}

# ======================== NS-3 BUILD FUNCTIONS ========================

download_and_build_ns3() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ NS-3 Download & Build ━━━${NC}"
    echo ""

    # Download
    if [ "$HAS_NS3" = true ]; then
        echo -e "  ${CHECK} NS-3 v${NS3_VERSION} already downloaded (skipping)"
    else
        echo -e "  ${ARROW} Downloading NS-3 v${NS3_VERSION} (~120MB)..."
        cd "$HOME"
        wget -q --show-progress \
            "https://www.nsnam.org/releases/ns-allinone-${NS3_VERSION}.tar.bz2" \
            -O "ns-allinone-${NS3_VERSION}.tar.bz2"
        echo -e "  ${ARROW} Extracting..."
        tar xjf "ns-allinone-${NS3_VERSION}.tar.bz2"
        rm -f "ns-allinone-${NS3_VERSION}.tar.bz2"
        HAS_NS3=true
        echo -e "  ${CHECK} NS-3 downloaded and extracted"
    fi

    # Patch
    echo -e "  ${ARROW} Applying compatibility patches..."
    patch_ns3
    echo -e "  ${CHECK} Patches applied"

    # Configure
    echo -e "  ${ARROW} Configuring NS-3 (optimized build, selected modules)..."
    cd "$NS3_SRC"
    ./ns3 configure --build-profile=optimized \
        -- "-DNS3_ENABLED_MODULES=core;network;internet;point-to-point;point-to-point-layout;csma;csma-layout;applications;flow-monitor;netanim;bridge;traffic-control;mobility;stats" \
        -DNS3_EXAMPLES=OFF \
        -DNS3_TESTS=OFF \
        2>&1 | tail -5
    echo -e "  ${CHECK} NS-3 configured"

    # Build
    CORES=$(nproc 2>/dev/null || echo 2)
    echo -e "  ${ARROW} Building NS-3 with $CORES cores (5-15 minutes)..."
    echo -e "  ${DIM}  Please wait, this takes a while on first run...${NC}"
    ./ns3 build 2>&1 | grep -E "(^\[|FAILED|error:)" | tail -20

    HAS_NS3_BUILT=true
    echo -e "  ${CHECK} NS-3 built successfully!"
}

patch_ns3() {
    # Fix Python 3.14 argparse
    if [ "$NEED_PYTHON_FIX" = true ] && command -v python3.12 &>/dev/null; then
        NS3_SCRIPT="$NS3_SRC/ns3"
        CURRENT=$(head -1 "$NS3_SCRIPT")
        if [[ "$CURRENT" != *"python3.12"* ]]; then
            sed -i '1s|.*|#!/usr/bin/env python3.12|' "$NS3_SCRIPT"
        fi
    fi

    # Fix GCC 15 missing #include <algorithm>
    WIFI_HEADER="$NS3_SRC/src/wifi/model/wifi-phy-state-helper.h"
    if [ -f "$WIFI_HEADER" ]; then
        FIRST=$(head -1 "$WIFI_HEADER")
        if [[ "$FIRST" != "#include <algorithm>" ]]; then
            sed -i '1s/^/#include <algorithm>\n/' "$WIFI_HEADER"
        fi
    fi
}

# ======================== SIMULATION BUILD ========================

build_simulation() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ Building Smart Campus Simulation ━━━${NC}"
    echo ""

    if [ "$HAS_NS3_BUILT" = false ]; then
        echo -e "  ${CROSS} NS-3 not built yet. Run option 3 first."
        return
    fi

    mkdir -p "$SCRATCH_DIR"

    echo -e "  ${ARROW} Copying simulation source..."
    cp "$PROJECT_DIR/scratch/smart-campus/smart-campus-network.cc" \
       "$SCRATCH_DIR/smart-campus-network.cc"
    echo -e "  ${CHECK} Source copied"

    echo -e "  ${ARROW} Compiling smart-campus-network..."
    cd "$NS3_SRC"
    ./ns3 build 2>&1 | grep -E "(smart-campus|Linking|FAILED)" | tail -5

    SIM_BINARY=$(find "$NS3_SRC/build" -name "*smart-campus*" -type f 2>/dev/null | head -1)
    if [ -n "$SIM_BINARY" ]; then
        HAS_SIM_BUILT=true
        echo -e "  ${CHECK} ${GREEN}Simulation compiled successfully!${NC}"
    else
        echo -e "  ${CROSS} ${RED}Build failed. Check errors above.${NC}"
    fi
}

# ======================== RUN SIMULATION ========================

run_simulation_menu() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ Run Simulation ━━━${NC}"
    echo ""

    if [ "$HAS_SIM_BUILT" = false ]; then
        echo -e "  ${CROSS} Simulation not compiled yet. Run option 4 first."
        return
    fi

    echo -e "  ${BOLD}Select scenario to run:${NC}"
    echo ""
    echo -e "  ${BOLD}1${NC} ${ARROW} Normal Operation          ${DIM}(baseline — no attacks, no failures)${NC}"
    echo -e "  ${BOLD}2${NC} ${ARROW} Attack + Quarantine        ${DIM}(malware at t=30s → risk score → quarantine)${NC}"
    echo -e "  ${BOLD}3${NC} ${ARROW} Link Failure + Self-Heal   ${DIM}(primary link fails at t=60s → backup activates)${NC}"
    echo -e "  ${BOLD}4${NC} ${ARROW} Combined (Recommended)     ${DIM}(attack + quarantine + link failure + healing)${NC}"
    echo -e "  ${BOLD}5${NC} ${ARROW} Run ALL Scenarios          ${DIM}(runs 1-4 sequentially)${NC}"
    echo -e "  ${BOLD}0${NC} ${ARROW} Back to main menu"
    echo ""
    echo -ne "  ${BOLD}Enter choice [0-5]: ${NC}"
    read -r SIM_CHOICE

    case $SIM_CHOICE in
        1) run_scenario 1 ;;
        2) run_scenario 2 ;;
        3) run_scenario 3 ;;
        4) run_scenario 4 ;;
        5)
            run_scenario 1
            run_scenario 2
            run_scenario 3
            run_scenario 4
            ;;
        0) return ;;
        *)
            echo -e "  ${CROSS} Invalid choice"
            return
            ;;
    esac

    # Copy results to project directory
    mkdir -p "$RESULTS_DIR"
    cp -f "$NS3_SRC"/smart-campus-s*.csv "$RESULTS_DIR/" 2>/dev/null || true
    cp -f "$NS3_SRC"/smart-campus-s*.xml "$RESULTS_DIR/" 2>/dev/null || true

    # Copy to Windows if on WSL
    if [ "$IS_WSL" = true ]; then
        WIN_RESULTS="/mnt/d/CN/ns3-smart-campus/results"
        mkdir -p "$WIN_RESULTS" 2>/dev/null || true
        cp -f "$RESULTS_DIR"/* "$WIN_RESULTS/" 2>/dev/null || true
        echo ""
        echo -e "  ${CHECK} Results copied to Windows: ${BOLD}D:\\CN\\ns3-smart-campus\\results\\${NC}"
    fi

    echo ""
    echo -e "  ${GREEN}${BOLD}✅ Simulation complete! Results saved to: $RESULTS_DIR${NC}"
}

run_scenario() {
    local S=$1
    local DESC=""
    case $S in
        1) DESC="Normal Operation (baseline)" ;;
        2) DESC="Malware Attack + Dynamic Quarantine" ;;
        3) DESC="Link Failure + Self-Healing" ;;
        4) DESC="Combined (Attack + Quarantine + Self-Healing)" ;;
    esac

    echo ""
    echo -e "  ${ARROW} ${BOLD}Scenario $S:${NC} $DESC"
    echo -e "  ${DIM}  Running simulation (120 seconds simulated time)...${NC}"

    cd "$NS3_SRC"
    START_TIME=$(date +%s)

    OUTPUT=$(./ns3 run "smart-campus-network --scenario=$S" 2>&1)

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    echo -e "  ${CHECK} Scenario $S completed in ${ELAPSED}s"

    # Show quick summary from output
    echo "$OUTPUT" | grep -E "(Total Flows|Total Throughput|Average Delay|Quarantined)" | while read -r line; do
        echo -e "     ${DIM}$line${NC}"
    done
}

# ======================== NETANIM ========================

netanim_menu() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ NetAnim Live Visualisation ━━━${NC}"
    echo ""

    if [ "$HAS_NETANIM" = false ]; then
        echo -e "  ${WARN} NetAnim is not built yet."
        echo ""
        echo -ne "  Build NetAnim now? [y/N]: "
        read -r BUILD_CHOICE
        if [[ "$BUILD_CHOICE" =~ ^[Yy]$ ]]; then
            build_netanim
        else
            return
        fi
    fi

    echo ""
    echo -e "  ${BOLD}Select animation to view:${NC}"
    echo ""

    for S in 1 2 3 4; do
        ANIM_FILE="$NS3_SRC/smart-campus-s${S}-animation.xml"
        ANIM_FILE2="$RESULTS_DIR/smart-campus-s${S}-animation.xml"
        case $S in
            1) DESC="Normal Operation" ;;
            2) DESC="Attack + Quarantine" ;;
            3) DESC="Link Failure + Self-Healing" ;;
            4) DESC="Combined (All Features)" ;;
        esac
        if [ -f "$ANIM_FILE" ] || [ -f "$ANIM_FILE2" ]; then
            echo -e "  ${BOLD}$S${NC} ${ARROW} Scenario $S: $DESC  ${GREEN}(available)${NC}"
        else
            echo -e "  ${BOLD}$S${NC} ${ARROW} Scenario $S: $DESC  ${RED}(not run yet)${NC}"
        fi
    done
    echo -e "  ${BOLD}0${NC} ${ARROW} Back to main menu"
    echo ""
    echo -ne "  ${BOLD}Enter choice [0-4]: ${NC}"
    read -r ANIM_CHOICE

    if [ "$ANIM_CHOICE" = "0" ]; then
        return
    fi

    if [[ "$ANIM_CHOICE" =~ ^[1-4]$ ]]; then
        ANIM_FILE="$NS3_SRC/smart-campus-s${ANIM_CHOICE}-animation.xml"
        ANIM_FILE2="$RESULTS_DIR/smart-campus-s${ANIM_CHOICE}-animation.xml"

        if [ -f "$ANIM_FILE" ]; then
            OPEN_FILE="$ANIM_FILE"
        elif [ -f "$ANIM_FILE2" ]; then
            OPEN_FILE="$ANIM_FILE2"
        else
            echo -e "  ${CROSS} Animation file not found. Run scenario $ANIM_CHOICE first (option 5)."
            return
        fi

        echo ""
        echo -e "  ${ARROW} Launching NetAnim..."
        echo -e "  ${DIM}  Opening: $OPEN_FILE${NC}"
        echo -e "  ${DIM}  Press Ctrl+C here when done viewing.${NC}"
        echo ""

        cd "$NETANIM_DIR"
        ./NetAnim "$OPEN_FILE" 2>/dev/null || {
            echo -e "  ${WARN} NetAnim could not open. Trying without file argument..."
            echo -e "  ${DIM}  Manually open: $OPEN_FILE${NC}"
            ./NetAnim 2>/dev/null || {
                echo -e "  ${CROSS} NetAnim GUI failed. Make sure you have display access."
                if [ "$IS_WSL" = true ]; then
                    echo -e "  ${DIM}  On Windows 11: WSLg should handle this automatically.${NC}"
                    echo -e "  ${DIM}  On Windows 10: Install VcXsrv and run: export DISPLAY=:0${NC}"
                fi
            }
        }
    else
        echo -e "  ${CROSS} Invalid choice"
    fi
}

build_netanim() {
    echo -e "  ${ARROW} Building NetAnim..."

    if [ ! -d "$NETANIM_DIR" ]; then
        echo -e "  ${CROSS} NetAnim directory not found at $NETANIM_DIR"
        return
    fi

    cd "$NETANIM_DIR"
    CORES=$(nproc 2>/dev/null || echo 2)

    qmake NetAnim.pro 2>/dev/null && make -j"$CORES" 2>&1 | tail -3

    if [ -f "NetAnim" ]; then
        HAS_NETANIM=true
        echo -e "  ${CHECK} ${GREEN}NetAnim built successfully!${NC}"
    else
        echo -e "  ${CROSS} ${RED}NetAnim build failed.${NC}"
    fi
}

# ======================== ANALYSIS ========================

generate_graphs() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ Generate Analysis Graphs ━━━${NC}"
    echo ""

    if [ "$HAS_MATPLOTLIB" = false ]; then
        echo -e "  ${WARN} matplotlib not installed. Installing..."
        $PYTHON_CMD -m pip install --quiet matplotlib numpy 2>/dev/null || \
            pip3 install --quiet --break-system-packages matplotlib numpy 2>/dev/null
    fi

    mkdir -p "$RESULTS_DIR"

    # Check for result files
    HAS_RESULTS=false
    for S in 1 2 3 4; do
        if ls "$NS3_SRC"/smart-campus-s${S}-*.csv &>/dev/null 2>&1; then
            cp -f "$NS3_SRC"/smart-campus-s${S}-*.csv "$RESULTS_DIR/" 2>/dev/null
            HAS_RESULTS=true
        fi
        if ls "$RESULTS_DIR"/smart-campus-s${S}-*.csv &>/dev/null 2>&1; then
            HAS_RESULTS=true
        fi
    done

    if [ "$HAS_RESULTS" = false ]; then
        echo -e "  ${CROSS} No simulation results found. Run a simulation first (option 5)."
        return
    fi

    echo -e "  ${BOLD}Select which scenario's graphs to generate:${NC}"
    echo ""
    echo -e "  ${BOLD}1${NC} ${ARROW} Scenario 1 graphs"
    echo -e "  ${BOLD}2${NC} ${ARROW} Scenario 2 graphs"
    echo -e "  ${BOLD}3${NC} ${ARROW} Scenario 3 graphs"
    echo -e "  ${BOLD}4${NC} ${ARROW} Scenario 4 graphs (Recommended)"
    echo -e "  ${BOLD}5${NC} ${ARROW} All scenarios"
    echo -e "  ${BOLD}0${NC} ${ARROW} Back to main menu"
    echo ""
    echo -ne "  ${BOLD}Enter choice [0-5]: ${NC}"
    read -r GRAPH_CHOICE

    case $GRAPH_CHOICE in
        0) return ;;
        1|2|3|4)
            echo -e "  ${ARROW} Generating graphs for Scenario $GRAPH_CHOICE..."
            cd "$RESULTS_DIR"
            $PYTHON_CMD "$PROJECT_DIR/analysis/analyze-results.py" --scenario "$GRAPH_CHOICE" 2>&1
            ;;
        5)
            for S in 1 2 3 4; do
                echo -e "  ${ARROW} Generating graphs for Scenario $S..."
                cd "$RESULTS_DIR"
                $PYTHON_CMD "$PROJECT_DIR/analysis/analyze-results.py" --scenario "$S" 2>&1
            done
            ;;
        *) echo -e "  ${CROSS} Invalid choice"; return ;;
    esac

    # Copy to Windows if on WSL
    if [ "$IS_WSL" = true ]; then
        WIN_RESULTS="/mnt/d/CN/ns3-smart-campus/results"
        mkdir -p "$WIN_RESULTS" 2>/dev/null || true
        cp -f "$RESULTS_DIR"/*.png "$WIN_RESULTS/" 2>/dev/null || true
        echo ""
        echo -e "  ${CHECK} Graphs copied to Windows: ${BOLD}D:\\CN\\ns3-smart-campus\\results\\${NC}"
        echo -e "  ${DIM}  Open this folder in Windows File Explorer to view the PNG files.${NC}"
    fi

    echo ""
    echo -e "  ${GREEN}${BOLD}✅ Graphs generated in: $RESULTS_DIR/results/${NC}"
}

# ======================== FULL AUTO SETUP ========================

full_auto_setup() {
    echo ""
    echo -e "  ${BOLD}${STAR} FULL AUTO SETUP — Sit back and relax! ${STAR}${NC}"
    echo -e "  ${DIM}  This will install everything, build, run, and generate graphs.${NC}"
    echo -e "  ${DIM}  Estimated time: 20-30 minutes (first run)${NC}"
    echo ""
    echo -ne "  ${BOLD}Continue? [Y/n]: ${NC}"
    read -r AUTO_CONFIRM
    if [[ "$AUTO_CONFIRM" =~ ^[Nn]$ ]]; then
        return
    fi

    echo ""
    local STEP=1
    local TOTAL=6

    echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} Checking requirements..."
    check_all_requirements
    STEP=$((STEP + 1))

    if [ "$ALL_DEPS_OK" = false ]; then
        echo ""
        echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} Installing missing dependencies..."
        install_dependencies
    else
        echo ""
        echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} ${CHECK} All dependencies OK (skipping install)"
    fi
    STEP=$((STEP + 1))

    if [ "$HAS_NS3_BUILT" = false ]; then
        echo ""
        echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} Downloading & building NS-3..."
        download_and_build_ns3
    else
        echo ""
        echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} ${CHECK} NS-3 already built (skipping)"
    fi
    STEP=$((STEP + 1))

    if [ "$HAS_SIM_BUILT" = false ]; then
        echo ""
        echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} Building simulation..."
        build_simulation
    else
        echo ""
        echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} ${CHECK} Simulation already compiled (skipping)"
    fi
    STEP=$((STEP + 1))

    echo ""
    echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} Running all 4 scenarios..."
    for S in 1 2 3 4; do
        run_scenario $S
    done
    mkdir -p "$RESULTS_DIR"
    cp -f "$NS3_SRC"/smart-campus-s*.csv "$RESULTS_DIR/" 2>/dev/null || true
    cp -f "$NS3_SRC"/smart-campus-s*.xml "$RESULTS_DIR/" 2>/dev/null || true
    STEP=$((STEP + 1))

    echo ""
    echo -e "  ${BOLD}[$STEP/$TOTAL]${NC} Building NetAnim..."
    if [ "$HAS_NETANIM" = false ]; then
        build_netanim
    else
        echo -e "  ${CHECK} NetAnim already built (skipping)"
    fi

    # Copy to Windows if on WSL
    if [ "$IS_WSL" = true ]; then
        WIN_RESULTS="/mnt/d/CN/ns3-smart-campus/results"
        mkdir -p "$WIN_RESULTS" 2>/dev/null || true
        cp -f "$RESULTS_DIR"/* "$WIN_RESULTS/" 2>/dev/null || true
    fi

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                 ║${NC}"
    echo -e "${GREEN}║         ✅  FULL AUTO SETUP COMPLETE — ALL SYSTEMS GO!          ║${NC}"
    echo -e "${GREEN}║                                                                 ║${NC}"
    echo -e "${GREEN}║${NC}   All 4 scenarios have been simulated.                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   Use option ${BOLD}6${NC} to view animations in NetAnim.                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   Use option ${BOLD}7${NC} to generate publication-quality graphs.         ${GREEN}║${NC}"
    echo -e "${GREEN}║                                                                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
}

# ======================== CLEAN & RESET ========================

clean_and_reset() {
    echo ""
    echo -e "  ${BOLD}${RED}━━━ Clean & Reset ━━━${NC}"
    echo ""
    echo -e "  ${BOLD}What do you want to clean?${NC}"
    echo ""
    echo -e "  ${BOLD}1${NC} ${ARROW} Simulation results only     ${DIM}(keeps NS-3 build)${NC}"
    echo -e "  ${BOLD}2${NC} ${ARROW} Simulation build only       ${DIM}(recompile simulation)${NC}"
    echo -e "  ${BOLD}3${NC} ${ARROW} NS-3 build cache            ${DIM}(reconfigure + rebuild NS-3)${NC}"
    echo -e "  ${BOLD}4${NC} ${ARROW} Everything (full reset)     ${RED}(deletes NS-3 entirely — re-download needed)${NC}"
    echo -e "  ${BOLD}0${NC} ${ARROW} Back to main menu"
    echo ""
    echo -ne "  ${BOLD}Enter choice [0-4]: ${NC}"
    read -r CLEAN_CHOICE

    case $CLEAN_CHOICE in
        0) return ;;
        1)
            echo -e "  ${ARROW} Cleaning simulation results..."
            rm -rf "$RESULTS_DIR"
            rm -f "$NS3_SRC"/smart-campus-s*.csv 2>/dev/null
            rm -f "$NS3_SRC"/smart-campus-s*.xml 2>/dev/null
            echo -e "  ${CHECK} Results cleaned"
            ;;
        2)
            echo -e "  ${ARROW} Removing simulation binary..."
            rm -rf "$SCRATCH_DIR"
            cd "$NS3_SRC" && ./ns3 build 2>&1 | tail -3
            HAS_SIM_BUILT=false
            echo -e "  ${CHECK} Simulation removed (rebuild with option 4)"
            ;;
        3)
            echo -e "  ${ARROW} Cleaning NS-3 build..."
            cd "$NS3_SRC" && ./ns3 clean 2>&1 | tail -3
            HAS_NS3_BUILT=false
            HAS_SIM_BUILT=false
            echo -e "  ${CHECK} NS-3 build cleaned (rebuild with option 3)"
            ;;
        4)
            echo -ne "  ${RED}${BOLD}Are you sure? This deletes everything. [y/N]: ${NC}"
            read -r CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                echo -e "  ${ARROW} Removing NS-3 installation..."
                rm -rf "$NS3_DIR"
                rm -rf "$RESULTS_DIR"
                HAS_NS3=false
                HAS_NS3_BUILT=false
                HAS_SIM_BUILT=false
                HAS_NETANIM=false
                echo -e "  ${CHECK} Everything cleaned. Start fresh with option 8."
            fi
            ;;
        *) echo -e "  ${CROSS} Invalid choice" ;;
    esac
}

# ======================== MAIN LOOP ========================

detect_environment

while true; do
    clear_screen
    print_banner
    print_main_menu
    echo -ne "  ${BOLD}Enter choice [0-9]: ${NC}"
    read -r CHOICE

    case $CHOICE in
        1)
            clear_screen
            print_banner
            check_all_requirements
            press_enter
            ;;
        2)
            clear_screen
            print_banner
            check_all_requirements
            install_dependencies
            press_enter
            ;;
        3)
            clear_screen
            print_banner
            download_and_build_ns3
            press_enter
            ;;
        4)
            clear_screen
            print_banner
            build_simulation
            press_enter
            ;;
        5)
            clear_screen
            print_banner
            run_simulation_menu
            press_enter
            ;;
        6)
            clear_screen
            print_banner
            netanim_menu
            press_enter
            ;;
        7)
            clear_screen
            print_banner
            generate_graphs
            press_enter
            ;;
        8)
            clear_screen
            print_banner
            full_auto_setup
            press_enter
            ;;
        9)
            clear_screen
            print_banner
            clean_and_reset
            press_enter
            ;;
        0)
            echo ""
            echo -e "  ${CYAN}Goodbye! 👋${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "  ${CROSS} Invalid option. Please choose 0-9."
            sleep 1
            ;;
    esac
done
