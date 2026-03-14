#!/bin/bash
# =============================================================================
# Home Lab Manager - System Administration Script for Debian Headless Servers
# =============================================================================
# This script provides a menu-driven interface for managing and monitoring
# a Debian server/home lab without a graphical interface.
#
# IMPORTANT SECURITY NOTES:
#   - This script runs without privileged operations
#   - This script is READ-ONLY for safety
#   - Only basic info display that won't affect system stability
#
# Features:
#   - System information display
#   - Real-time process monitoring
#   - Network information
#   - Service status
#   - Security diagnostics (read-only)
#   - Quick actions (user-level, no system modification)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Color codes for output formatting
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# -----------------------------------------------------------------------------
# Helper functions for bat-style formatting
# -----------------------------------------------------------------------------
separator() {
    echo -e "${DIM}$(printf '─%.0s' {1..60})${NC}"
}

separator_bold() {
    echo -e "${BOLD}$(printf '═%.0s' {1..60})${NC}"
}

section_header() {
    echo -e "\n${BOLD}${CYAN}▸ $1${NC}"
    separator
}

# Table header with columns
table_header() {
    printf "${BOLD}${CYAN}%-20s %s${NC}\n" "$1" "$2"
}

# Table row
table_row() {
    printf "  %-18s %s\n" "$1" "$2"
}

# Status indicator (green/yellow/red)
status_ok()    { echo -e "${GREEN}●${NC} $1"; }
status_warn()  { echo -e "${YELLOW}○${NC} $1"; }
status_err()   { echo -e "${RED}●${NC} $1"; }

# -----------------------------------------------------------------------------
# Logging functions for consistent output
# -----------------------------------------------------------------------------
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# -----------------------------------------------------------------------------
# Display main menu
# -----------------------------------------------------------------------------
show_menu() {
    clear
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║         🖥️  HOME LAB MANAGER            ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}1)${NC} 📊 System Information"
    echo -e "  ${BOLD}2)${NC} 🔄 Process Monitoring"
    echo -e "  ${BOLD}3)${NC} 🌐 Network Information"
    echo -e "  ${BOLD}4)${NC} 📦 Service Status"
    echo -e "  ${BOLD}5)${NC} 🛡️  Security Check"
    echo -e "  ${BOLD}6)${NC} ⚡ Quick Actions"
    echo -e "  ${BOLD}0)${NC} 🚪 Exit"
    echo ""
    echo -ne "${BOLD}Select an option:${NC} "
}

# -----------------------------------------------------------------------------
# Display comprehensive system information
# Safe function that only reads system files
# -----------------------------------------------------------------------------
system_info() {
    clear
    separator_bold
    echo -e "${BOLD}${BLUE}  📊 SYSTEM INFORMATION${NC}"
    separator_bold

    section_header "🖥️  System"
    table_row "Hostname" "$(hostname)"
    table_row "OS" "$(uname -s)"
    table_row "Kernel" "$(uname -r)"
    table_row "Architecture" "$(uname -m)"
    table_row "Uptime" "$(uptime -p 2>/dev/null || uptime)"

    section_header "📅 Date & Time"
    table_row "Current" "$(date '+%A, %B %d, %Y - %H:%M:%S')"
    if [ -f /etc/timezone ]; then
        table_row "Timezone" "$(cat /etc/timezone)"
    fi

    section_header "💻 Hardware"
    if command -v nproc &>/dev/null; then
        table_row "CPU Cores" "$(nproc)"
    fi
    if [ -f /proc/meminfo ]; then
        mem_total=$(awk '/^MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
        mem_available=$(awk '/^MemAvailable/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
        table_row "RAM" "~${mem_available}G / ${mem_total}G available"
    fi

    section_header "🔄 Swap"
    if [ -f /proc/swaps ]; then
        awk 'NR>1 {printf "  %-18s %s (%s)\n", $1, $2, $3}' /proc/swaps
    fi

    section_header "💾 Disk Usage"
    df -h / | awk 'NR==2 {printf "  %-18s %s / %s (%s used)\n", "Root (/)", $3, $2, $5}'
    if mountpoint -q /home 2>/dev/null; then
        df -h /home | awk 'NR==2 {printf "  %-18s %s / %s (%s used)\n", "Home (/home)", $3, $2, $5}'
    fi

    section_header "👤 User"
    table_row "Current user" "$(whoami)"
    table_row "UID" "$(id -u)"
    table_row "Shell" "$SHELL"
    if [ -n "${SSH_CLIENT:-}" ]; then
        table_row "SSH from" "$SSH_CLIENT"
    fi

    separator
    echo ""
    read -p "Press Enter to continue..."
}

# -----------------------------------------------------------------------------
# Real-time process monitoring
# Displays top processes by memory and CPU usage
# Updates every 3 seconds - press 'q' or Ctrl+C to exit
# -----------------------------------------------------------------------------
monitor_processes() {
    cleanup() {
        echo -e "\n${YELLOW}Returning to menu...${NC}"
        exit_code=0
    }
    trap cleanup INT
    
    local running=true
    while $running; do
        clear
        separator
        echo -e "${BOLD}🔄 PROCESS MONITORING${NC}"
        separator
        echo -e "${BOLD}Updates every 3 seconds. Press 'q' or Ctrl+C to exit.${NC}\n"

        # Header like bat style
        printf "${BOLD}${CYAN}%-10s %-8s %-6s %-6s %-8s %s${NC}\n" "USER" "%MEM" "%CPU" "PID" "TTY" "COMMAND"
        echo -e "${DIM}$(printf '=%.0s' {1..70})${NC}"

        # Top processes by memory - clean format
        ps aux --sort=-%mem | awk 'NR>1 && NR<=11 {printf "%-10s %-8s %-6s %-6s %-8s %s\n", $1, $3, $2, $4, $7, $11}'

        echo ""
        printf "${BOLD}${YELLOW}%-10s %-8s %-6s %-6s %-8s %s${NC}\n" "USER" "%MEM" "%CPU" "PID" "TTY" "COMMAND"
        echo -e "${DIM}$(printf '=%.0s' {1..70})${NC}"

        # Top processes by CPU - clean format  
        ps aux --sort=-%cpu | awk 'NR>1 && NR<=11 {printf "%-10s %-8s %-6s %-6s %-8s %s\n", $1, $3, $2, $4, $7, $11}'

        echo ""
        separator
        echo -e "${BOLD}System:${NC}  Uptime: $(uptime -p 2>/dev/null || uptime)  |  Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')  |  Procs: $(ps aux | wc -l)"

        # Check if user pressed 'q' without blocking
        if IFS= read -r -t 1 -n 1 key 2>/dev/null; then
            [[ "$key" == "q" ]] && break
        fi
        
        sleep 3
    done
    
    trap - INT
}

# -----------------------------------------------------------------------------
# Network information display
# Shows network interfaces, connections, and routing
# All read-only
# -----------------------------------------------------------------------------
network_info() {
    clear
    separator_bold
    echo -e "${BOLD}${BLUE}  🌐 NETWORK INFORMATION${NC}"
    separator_bold

    section_header "Network Interfaces"
    printf "${BOLD}%-15s %-10s %s${NC}\n" "INTERFACE" "STATE" "ADDRESS"
    separator
    ip -br addr show | while read -r iface state addr; do
        printf "%-15s ${GREEN}%-10s${NC} %s\n" "$iface" "$state" "$addr"
    done

    section_header "Open Ports (Listening)"
    printf "${BOLD}%-8s %-20s %s${NC}\n" "PROTO" "LOCAL ADDRESS" "SERVICE"
    separator
    if command -v ss &>/dev/null; then
        ss -tulnp 2>/dev/null | grep LISTEN | head -10 | while read -r line; do
            proto=$(echo "$line" | awk '{print $1}')
            local_addr=$(echo "$line" | awk '{print $5}')
            service=$(echo "$line" | awk '{print $6}' | cut -d'"' -f2 | cut -d'(' -f1)
            printf "%-8s %-20s %s\n" "$proto" "$local_addr" "${service:-unknown}"
        done
    fi

    section_header "Connection States"
    printf "${BOLD}%-15s %s${NC}\n" "STATE" "COUNT"
    separator
    if command -v ss &>/dev/null; then
        ss -tan 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -5 | while read -r count state; do
            printf "%-15s ${CYAN}%s${NC}\n" "$state" "$count"
        done
    fi

    section_header "Routing & DNS"
    gateway=$(ip route | grep default | awk '{print $3}')
    table_row "Default Gateway" "${gateway:-none}"
    if [ -f /etc/resolv.conf ]; then
        dns_servers=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ', ')
        table_row "DNS Servers" "${dns_servers%,}"
    fi

    separator
    echo ""
    read -p "Press Enter to continue..."
}

# -----------------------------------------------------------------------------
# Service status display
# Shows systemd services and their status
# -----------------------------------------------------------------------------
show_services() {
    clear
    separator_bold
    echo -e "${BOLD}${BLUE}  📦 SERVICE STATUS${NC}"
    separator_bold

    section_header "User Services"
    printf "${BOLD}%-20s %-15s %s${NC}\n" "SERVICE" "STATUS" "INFO"
    separator
    for svc in nginx apache2 postgresql mysql redis ssh cron rsyslog; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            printf "%-20s ${GREEN}%-15s${NC} %s\n" "$svc" "Active" "$(systemctl show -p MainPID --value $svc 2>/dev/null | grep -q '^[0-9]' && echo "PID: $(systemctl show -p MainPID --value $svc)")"
        elif systemctl is-enabled --quiet "$svc" 2>/dev/null; then
            printf "%-20s ${YELLOW}%-15s${NC} %s\n" "$svc" "Enabled" "(inactive)"
        fi
    done

    separator
    echo ""
    read -p "Press Enter to continue..."
}

# -----------------------------------------------------------------------------
# Security check function
# Performs basic security diagnostics - READ ONLY
# -----------------------------------------------------------------------------
security_check() {
    clear
    separator_bold
    echo -e "${BOLD}${BLUE}  🛡️  SECURITY CHECK${NC}"
    separator_bold

    section_header "Open Ports"
    if command -v ss &>/dev/null; then
        open_ports=$(ss -tulnp 2>/dev/null | grep LISTEN | wc -l)
        table_row "Total open ports" "$open_ports"
        printf "${BOLD}%-8s %-20s %s${NC}\n" "PROTO" "PORT" "SERVICE"
        separator
        ss -tulnp 2>/dev/null | grep LISTEN | head -10 | while read -r line; do
            proto=$(echo "$line" | awk '{print $1}')
            port=$(echo "$line" | awk '{print $5}' | cut -d':' -f2)
            service=$(echo "$line" | awk '{print $6}' | cut -d'"' -f2 | cut -d'(' -f1)
            printf "%-8s %-20s %s\n" "$proto" "$port" "${service:-unknown}"
        done
    fi

    section_header "Users with Shell Access"
    printf "${BOLD}%-20s %s${NC}\n" "USER" "SHELL"
    separator
    getent passwd | grep -E '/bin/(bash|sh|zsh)$' | awk -F: '{printf "%-20s %s\n", $1, $7}'

    section_header "Firewall"
    if command -v ufw &>/dev/null; then
        ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "inactive"; then
            status_warn "UFW is inactive"
        else
            status_ok "$ufw_status"
        fi
    else
        status_warn "No firewall tool detected"
    fi

    separator
    echo ""
    read -p "Press Enter to continue..."
}

# -----------------------------------------------------------------------------
# Quick actions menu
# User-level actions only - no system modification
# -----------------------------------------------------------------------------
quick_actions() {
    clear
    separator
    echo -e "${BOLD}⚡ QUICK ACTIONS${NC}"
    separator

    echo ""
    echo -e "  ${BOLD}1)${NC} 📊 Disk usage by folder"
    echo -e "  ${BOLD}2)${NC} 🔌 Connected USB devices"
    echo -e "  ${BOLD}3)${NC} 📄 View system logs (journalctl)"
    echo -e "  ${BOLD}4)${NC} 📈 System resources summary"
    echo -e "  ${BOLD}5)${NC} 🔍 Check specific process"
    echo -e "  ${BOLD}6)${NC} 🌡️  CPU temperature (if available)"
    echo -e "  ${BOLD}0)${NC} ↩️  Back to main menu"
    echo ""
    echo -ne "Select an option: "

    read -r choice
    case $choice in
        1)
            echo -ne "Folder to analyze (default: $HOME): "
            read -r folder
            folder=${folder:-$HOME}
            if [ -d "$folder" ]; then
                echo ""
                du -h "$folder" 2>/dev/null | sort -rh | head -15
            else
                log_error "Invalid folder"
            fi
            ;;
        2)
            if command -v lsusb &>/dev/null; then
                lsusb
            elif [ -r /proc/bus/usb/devices ]; then
                cat /proc/bus/usb/devices | grep -E "^T:|P:" | head -20
            else
                echo "USB info not available"
            fi
            ;;
        3)
            echo "Recent system messages (Ctrl+C to exit):"
            echo ""
            if command -v journalctl &>/dev/null; then
                journalctl -n 50 --no-pager
            elif [ -f /var/log/syslog ]; then
                tail -50 /var/log/syslog
            else
                log_error "No log viewer available"
            fi
            ;;
        4)
            echo -e "\n${BOLD}System Resources:${NC}"
            echo "    CPU Load:    $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
            echo "    Memory:      $(free -h | awk '/^Mem/ {print $3 " / " $2}')"
            echo "    Swap:        $(free -h | awk '/^Swap/ {print $1}')"
            echo "    Disk I/O:    $(cat /proc/diskstats | awk '{i+=$6; o+=$10} END {print i " reads, " o " writes"}' | head -1)"
            echo "    Processes:   $(ps aux | wc -l)"
            ;;
        5)
            echo -ne "Process name to search: "
            read -r procname
            if [ -n "$procname" ]; then
                echo ""
                ps aux | grep -E "$procname" | grep -v grep | head -10 || echo "No processes found"
            else
                log_error "No process name provided"
            fi
            ;;
        6)
            if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
                temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
                if [ -n "$temp" ]; then
                    echo "    CPU Temperature: $((temp / 1000))°C"
                fi
            elif command -v vcgencmd &>/dev/null; then
                vcgencmd measure_temp
            else
                echo "    Temperature not available"
            fi
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
}

# -----------------------------------------------------------------------------
# Main function - runs the interactive menu loop
# -----------------------------------------------------------------------------
main() {
    while true; do
        show_menu
        read -r choice
        case $choice in
            1) system_info ;;
            2) monitor_processes ;;
            3) network_info ;;
            4) show_services ;;
            5) security_check ;;
            6) quick_actions ;;
            0)
                clear
                echo -e "${GREEN}Goodbye! 👋${NC}"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Help message and command-line options
# -----------------------------------------------------------------------------
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Home Lab Manager - System Administration Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  --menu, -m      Show interactive menu (default)"
    echo "  --sysinfo       Show system information"
    echo "  --monitor       Start process monitoring"
    echo "  --network       Show network information"
    echo "  --services      Show service status"
    echo "  --security      Run security check"
    echo "  --help, -h      Show this help"
    echo ""
    echo "Security Notes:"
    echo "  - This script runs without sudo"
    echo "  - This script is READ-ONLY for safety"
    exit 0
fi

# -----------------------------------------------------------------------------
# Parse command-line arguments
# -----------------------------------------------------------------------------
case "${1:-menu}" in
    --menu|-m) main ;;
    --sysinfo) system_info ;;
    --monitor) monitor_processes ;;
    --network) network_info ;;
    --services) show_services ;;
    --security) security_check ;;
    *) main ;;
esac
