#!/bin/bash
set -e

# OpenClaw Ansible Installer
# This script installs Ansible if needed and runs the OpenClaw playbook

# Enable 256 colors
export TERM=xterm-256color

# Force color support
if [ -z "$COLORTERM" ]; then
    export COLORTERM=truecolor
fi

# Colors (with 256-color support)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   OpenClaw Ansible Installer           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect operating system
if command -v apt-get &> /dev/null; then
    echo -e "${GREEN}✓ Detected: Debian/Ubuntu Linux${NC}"
else
    echo -e "${RED}✗ Error: Unsupported operating system${NC}"
    echo -e "${RED}  This installer supports: Debian/Ubuntu Linux only${NC}"
    exit 1
fi

# Determine sudo usage
if [ "$EUID" -eq 0 ]; then
    echo -e "${GREEN}✓ Running as root${NC}"
    SUDO=""
else
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}✗ Error: sudo is not installed${NC}"
        echo -e "${RED}  Please install sudo or run as root${NC}"
        exit 1
    fi
    SUDO="sudo"
fi

echo ""
echo -e "${BLUE}[1/3] Installing Ansible...${NC}"

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${YELLOW}  Ansible not found, installing...${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y ansible git
    echo -e "${GREEN}  ✓ Ansible installed${NC}"
else
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    echo -e "${GREEN}  ✓ Ansible already installed (${ANSIBLE_VERSION})${NC}"
fi

echo ""
echo -e "${BLUE}[2/3] Installing Ansible collections...${NC}"
ansible-galaxy collection install -r requirements.yml
echo -e "${GREEN}  ✓ Collections installed${NC}"

echo ""
echo -e "${BLUE}[3/3] Verifying setup...${NC}"
ansible-playbook playbook.yml --syntax-check > /dev/null 2>&1
echo -e "${GREEN}  ✓ Playbook syntax valid${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Setup Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo -e "  1. Run the playbook:"
echo -e "     ${YELLOW}./run-playbook.sh${NC}"
echo ""
echo -e "  2. (Optional) Enable Tailscale:"
echo -e "     ${YELLOW}./run-playbook.sh -e tailscale_enabled=true${NC}"
echo ""
echo -e "  3. (Optional) Use custom variables:"
echo -e "     ${YELLOW}./run-playbook.sh -e @vars.yml${NC}"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo -e "  • Configuration: ${BLUE}docs/configuration.md${NC}"
echo -e "  • Architecture:  ${BLUE}docs/architecture.md${NC}"
echo ""
