#!/usr/bin/env bash
# GDFP - Google Domain Fronting Proxy Installer
# Creator: D3nte | Original project: masterking32/MasterHttpRelayVPN
# Target: Ubuntu 22.04 / Ubuntu 22+

# ─── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Paths ──────────────────────────────────────────────────────────────────────
INSTALL_DIR="/opt/gdfp"
SERVICE_NAME="gdfp"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
CONFIG_FILE="${INSTALL_DIR}/config.json"
PID_FILE="/var/run/gdfp.pid"
LOG_FILE="/var/log/gdfp.log"
REPO_URL="https://github.com/masterking32/MasterHttpRelayVPN/archive/refs/heads/python_testing.zip"

# ─── Helpers ────────────────────────────────────────────────────────────────────
hr() {
    echo -e "${DIM}──────────────────────────────────────────────────────────────────────${RESET}"
}

pause() {
    echo ""
    read -rp "  Press [Enter] to return to menu..." _dummy
}

# ─── Status Detection ───────────────────────────────────────────────────────────
is_installed() {
    [[ -f "${INSTALL_DIR}/main.py" ]] && return 0 || return 1
}

is_running() {
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        return 0
    fi
    return 1
}

get_proxy_addr() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        local host port
        host=$(python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('listen_host','127.0.0.1'))" 2>/dev/null)
        port=$(python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('listen_port',8085))" 2>/dev/null)
        echo "${host:-127.0.0.1}:${port:-8085}"
    else
        echo "N/A"
    fi
}

# ─── Header ─────────────────────────────────────────────────────────────────────
show_header() {
    clear
    echo ""
    echo -e "  ${BOLD}${CYAN} ██████╗ ██████╗ ███████╗██████╗ ${RESET}"
    echo -e "  ${BOLD}${CYAN}██╔════╝ ██╔══██╗██╔════╝██╔══██╗${RESET}"
    echo -e "  ${BOLD}${CYAN}██║  ███╗██║  ██║█████╗  ██████╔╝${RESET}"
    echo -e "  ${BOLD}${CYAN}██║   ██║██║  ██║██╔══╝  ██╔═══╝ ${RESET}"
    echo -e "  ${BOLD}${CYAN}╚██████╔╝██████╔╝██║     ██║     ${RESET}"
    echo -e "  ${BOLD}${CYAN} ╚═════╝ ╚═════╝ ╚═╝     ╚═╝     ${RESET}"
    echo ""
    echo -e "  ${WHITE}by ${BOLD}D3nte${RESET}   ${DIM}(original project: masterking32/MasterHttpRelayVPN)${RESET}"
    hr
    # Status line
    if is_installed; then
        echo -ne "  Core Status : ${GREEN}${BOLD}Installed${RESET}   "
    else
        echo -ne "  Core Status : ${RED}${BOLD}Not Installed${RESET}   "
    fi

    if is_running; then
        local addr
        addr=$(get_proxy_addr)
        echo -e "Proxy Status : ${GREEN}${BOLD}Running${RESET}  ${DIM}(${addr})${RESET}"
    else
        echo -e "Proxy Status : ${YELLOW}${BOLD}Stopped${RESET}"
    fi
    hr
    echo ""
}

# ─── Main Menu ──────────────────────────────────────────────────────────────────
show_menu() {
    echo -e "  ${BOLD}${WHITE}Main Menu${RESET}"
    echo ""
    echo -e "   ${CYAN}1)${RESET}  Install Prerequisites  ${DIM}(requirements.txt)${RESET}"
    echo -e "   ${CYAN}2)${RESET}  Install GDFP Script"
    echo -e "   ${CYAN}3)${RESET}  Generate Xray Outbound Config"
    echo -e "   ${CYAN}4)${RESET}  Status & Logs"
    echo -e "   ${CYAN}5)${RESET}  Uninstall / Disable"
    echo ""
    echo -e "   ${RED}0)${RESET}  Exit"
    echo ""
    hr
    echo -ne "  ${BOLD}Select option: ${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPTION 1 — Install Prerequisites
# ═══════════════════════════════════════════════════════════════════════════════
install_prerequisites() {
    show_header
    echo -e "  ${BOLD}[1] Install Prerequisites${RESET}"
    echo ""

    # Check python3
    echo -ne "  Checking Python 3 ... "
    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}NOT FOUND${RESET}"
        echo -e "  ${YELLOW}Installing python3...${RESET}"
        apt-get update -qq && apt-get install -y python3 python3-pip unzip curl 2>&1 | tail -5
    else
        local pyver
        pyver=$(python3 --version 2>&1)
        echo -e "${GREEN}OK${RESET}  ${DIM}(${pyver})${RESET}"
    fi

    # Check pip
    echo -ne "  Checking pip3    ... "
    if ! command -v pip3 &>/dev/null; then
        echo -e "${RED}NOT FOUND${RESET}"
        echo -e "  ${YELLOW}Installing pip3...${RESET}"
        apt-get install -y python3-pip 2>&1 | tail -3
    else
        echo -e "${GREEN}OK${RESET}"
    fi

    # Check unzip / curl
    for pkg in unzip curl wget; do
        echo -ne "  Checking ${pkg}     ... "
        if ! command -v "${pkg}" &>/dev/null; then
            echo -e "${RED}NOT FOUND${RESET} — installing..."
            apt-get install -y "${pkg}" -qq
        else
            echo -e "${GREEN}OK${RESET}"
        fi
    done

    echo ""
    # Install Python packages from requirements.txt
    if [[ -f "${INSTALL_DIR}/requirements.txt" ]]; then
        echo -e "  ${YELLOW}Installing Python packages from requirements.txt...${RESET}"
        pip3 install -r "${INSTALL_DIR}/requirements.txt" --break-system-packages 2>&1
        echo ""
        echo -e "  ${GREEN}✔  Prerequisites installed successfully.${RESET}"
    else
        echo -e "  ${YELLOW}GDFP not installed yet — requirements.txt not found.${RESET}"
        echo -e "  ${DIM}Please run option 2 (Install GDFP) first, or install manually.${RESET}"
        echo ""
        echo -e "  ${DIM}Manual install after option 2:${RESET}"
        echo -e "  ${DIM}  pip3 install cryptography h2${RESET}"
    fi
    pause
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPTION 2 — Install Script + Interactive Config
# ═══════════════════════════════════════════════════════════════════════════════
install_script() {
    show_header
    echo -e "  ${BOLD}[2] Install GDFP Script${RESET}"
    echo ""

    # ── Download project ──────────────────────────────────────────────────────
    if [[ -f "${INSTALL_DIR}/main.py" ]]; then
        echo -e "  ${YELLOW}GDFP is already installed at ${INSTALL_DIR}.${RESET}"
        echo -ne "  Reinstall / overwrite? [y/N]: "
        read -r ans
        [[ "${ans,,}" != "y" ]] && { pause; return; }
    fi

    echo -e "  ${CYAN}Downloading project...${RESET}"
    mkdir -p "${INSTALL_DIR}"
    TMP_ZIP=$(mktemp /tmp/gdfp_XXXXX.zip)

    if ! wget -q --show-progress -O "${TMP_ZIP}" "${REPO_URL}"; then
        echo -e "  ${RED}Download failed. Check your internet connection.${RESET}"
        pause; return
    fi

    echo -e "  ${CYAN}Extracting...${RESET}"
    TMP_DIR=$(mktemp -d /tmp/gdfp_src_XXXXX)
    unzip -q "${TMP_ZIP}" -d "${TMP_DIR}"
    cp -r "${TMP_DIR}"/MasterHttpRelayVPN-python_testing/. "${INSTALL_DIR}/"
    rm -rf "${TMP_ZIP}" "${TMP_DIR}"
    echo -e "  ${GREEN}✔  Files extracted to ${INSTALL_DIR}${RESET}"
    echo ""

    # ── Install requirements ──────────────────────────────────────────────────
    echo -e "  ${CYAN}Installing Python requirements...${RESET}"
    pip3 install -r "${INSTALL_DIR}/requirements.txt" --break-system-packages -q
    echo -e "  ${GREEN}✔  Requirements installed.${RESET}"
    echo ""
    hr

    # ── Interactive config ────────────────────────────────────────────────────
    echo -e "  ${BOLD}${WHITE}Configuration Setup${RESET}"
    echo -e "  ${DIM}Press [Enter] to accept the default value shown in [brackets].${RESET}"
    echo ""

    # ── MODE ──────────────────────────────────────────────────────────────────
    echo -e "  ${BOLD}Select Mode:${RESET}"
    echo ""
    echo -e "   ${CYAN}1)${RESET} ${BOLD}apps_script${RESET}     — Free Google account. Easiest, no server needed."
    echo -e "   ${CYAN}2)${RESET} ${BOLD}google_fronting${RESET} — Requires your own Google Cloud Run service."
    echo -e "   ${CYAN}3)${RESET} ${BOLD}domain_fronting${RESET} — Requires a Cloudflare Worker."
    echo -e "   ${CYAN}4)${RESET} ${BOLD}custom_domain${RESET}   — Requires a custom domain on Cloudflare."
    echo ""
    echo -e "  ${DIM}Most users should choose option 1 (apps_script).${RESET}"
    echo ""
    while true; do
        echo -ne "  Mode [1-4, default=1]: "
        read -r mode_choice
        mode_choice="${mode_choice:-1}"
        case "${mode_choice}" in
            1) CFG_MODE="apps_script";     break ;;
            2) CFG_MODE="google_fronting"; break ;;
            3) CFG_MODE="domain_fronting"; break ;;
            4) CFG_MODE="custom_domain";   break ;;
            *) echo -e "  ${RED}Invalid choice. Enter 1-4.${RESET}" ;;
        esac
    done
    echo -e "  ${GREEN}✔  Mode: ${CFG_MODE}${RESET}"
    echo ""

    # ── MANDATORY: script_id ──────────────────────────────────────────────────
    if [[ "${CFG_MODE}" == "apps_script" || "${CFG_MODE}" == "google_fronting" ]]; then
        echo -e "  ${BOLD}Script / Deployment ID${RESET}  ${RED}(required)${RESET}"
        echo -e "  ${DIM}Google Apps Script → Deploy → Manage deployments → copy the Deployment ID.${RESET}"
        while true; do
            echo -ne "  script_id: "
            read -r CFG_SCRIPT_ID
            CFG_SCRIPT_ID="${CFG_SCRIPT_ID// /}"
            if [[ -z "${CFG_SCRIPT_ID}" ]]; then
                echo -e "  ${RED}script_id cannot be empty.${RESET}"
            else
                break
            fi
        done
        echo ""
    else
        # For cloudflare modes, worker_host or custom_domain may be needed
        echo -e "  ${BOLD}Worker Host / Custom Domain${RESET}  ${RED}(required for this mode)${RESET}"
        echo -ne "  worker_host (e.g. my-worker.workers.dev): "
        read -r CFG_WORKER_HOST
        CFG_WORKER_HOST="${CFG_WORKER_HOST// /}"
        echo ""
        if [[ "${CFG_MODE}" == "custom_domain" ]]; then
            echo -ne "  custom_domain (e.g. proxy.yourdomain.com): "
            read -r CFG_CUSTOM_DOMAIN
            CFG_CUSTOM_DOMAIN="${CFG_CUSTOM_DOMAIN// /}"
            echo ""
        fi
        CFG_SCRIPT_ID=""
    fi

    # ── MANDATORY: auth_key ───────────────────────────────────────────────────
    echo -e "  ${BOLD}Auth Key (secret password)${RESET}  ${RED}(required)${RESET}"
    echo -e "  ${DIM}Must match AUTH_KEY in your Google Apps Script / Worker code.${RESET}"
    while true; do
        echo -ne "  auth_key: "
        read -r CFG_AUTH_KEY
        if [[ -z "${CFG_AUTH_KEY}" ]]; then
            echo -e "  ${RED}auth_key cannot be empty.${RESET}"
        else
            break
        fi
    done
    echo ""

    # ── OPTIONAL defaults ─────────────────────────────────────────────────────
    echo -e "  ${BOLD}Network Settings${RESET}  ${DIM}(press Enter for defaults)${RESET}"
    echo ""

    echo -ne "  google_ip     [216.239.38.120]: "
    read -r CFG_GOOGLE_IP
    CFG_GOOGLE_IP="${CFG_GOOGLE_IP:-216.239.38.120}"

    echo -ne "  front_domain  [www.google.com]: "
    read -r CFG_FRONT_DOMAIN
    CFG_FRONT_DOMAIN="${CFG_FRONT_DOMAIN:-www.google.com}"

    echo -ne "  listen_host   [127.0.0.1]: "
    read -r CFG_LISTEN_HOST
    CFG_LISTEN_HOST="${CFG_LISTEN_HOST:-127.0.0.1}"

    echo -ne "  listen_port   [8085]: "
    read -r CFG_LISTEN_PORT
    CFG_LISTEN_PORT="${CFG_LISTEN_PORT:-8085}"
    # Validate port
    if ! [[ "${CFG_LISTEN_PORT}" =~ ^[0-9]+$ ]] || (( CFG_LISTEN_PORT < 1 || CFG_LISTEN_PORT > 65535 )); then
        echo -e "  ${YELLOW}Invalid port, using default 8085.${RESET}"
        CFG_LISTEN_PORT=8085
    fi

    echo ""
    echo -e "  ${BOLD}Logging & SSL${RESET}"
    echo ""
    echo -e "  log_level options: DEBUG / INFO / WARNING / ERROR"
    echo -ne "  log_level     [INFO]: "
    read -r CFG_LOG_LEVEL
    CFG_LOG_LEVEL="${CFG_LOG_LEVEL:-INFO}"
    CFG_LOG_LEVEL="${CFG_LOG_LEVEL^^}"
    case "${CFG_LOG_LEVEL}" in
        DEBUG|INFO|WARNING|ERROR) ;;
        *) CFG_LOG_LEVEL="INFO" ;;
    esac

    echo -ne "  verify_ssl    [true] (true/false): "
    read -r CFG_VERIFY_SSL
    CFG_VERIFY_SSL="${CFG_VERIFY_SSL:-true}"
    [[ "${CFG_VERIFY_SSL,,}" == "false" ]] && CFG_VERIFY_SSL="false" || CFG_VERIFY_SSL="true"

    echo ""
    hr

    # ── Build config.json ─────────────────────────────────────────────────────
    echo -e "  ${CYAN}Writing config.json ...${RESET}"

    # Build JSON with python3 for clean formatting
    python3 - <<PYEOF
import json, sys

cfg = {
    "mode": "${CFG_MODE}",
    "google_ip": "${CFG_GOOGLE_IP}",
    "front_domain": "${CFG_FRONT_DOMAIN}",
    "listen_host": "${CFG_LISTEN_HOST}",
    "listen_port": int("${CFG_LISTEN_PORT}"),
    "log_level": "${CFG_LOG_LEVEL}",
    "verify_ssl": "${CFG_VERIFY_SSL}" == "true",
    "hosts": {}
}

script_id = "${CFG_SCRIPT_ID}".strip()
if script_id:
    cfg["script_id"] = script_id
    cfg["auth_key"] = "${CFG_AUTH_KEY}"

worker_host = "${CFG_WORKER_HOST:-}".strip()
if worker_host:
    cfg["worker_host"] = worker_host
    cfg["auth_key"] = "${CFG_AUTH_KEY}"

custom_domain = "${CFG_CUSTOM_DOMAIN:-}".strip()
if custom_domain:
    cfg["custom_domain"] = custom_domain

if "auth_key" not in cfg:
    cfg["auth_key"] = "${CFG_AUTH_KEY}"

with open("${CONFIG_FILE}", "w") as f:
    json.dump(cfg, f, indent=2)

print("  Config written to ${CONFIG_FILE}")
PYEOF

    echo ""
    # ── Create systemd service ─────────────────────────────────────────────────
    PYTHON_BIN=$(command -v python3)
    echo -e "  ${CYAN}Creating systemd service...${RESET}"

    cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=GDFP - Google Domain Fronting Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${PYTHON_BIN} ${INSTALL_DIR}/main.py -c ${CONFIG_FILE}
Restart=on-failure
RestartSec=5
StandardOutput=append:${LOG_FILE}
StandardError=append:${LOG_FILE}

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}" --quiet

    echo -e "  ${GREEN}✔  Service created and enabled.${RESET}"
    echo ""

    # ── Start service ─────────────────────────────────────────────────────────
    echo -ne "  Start GDFP proxy now? [Y/n]: "
    read -r start_now
    start_now="${start_now:-y}"
    if [[ "${start_now,,}" == "y" ]]; then
        systemctl start "${SERVICE_NAME}"
        sleep 1
        if is_running; then
            echo -e "  ${GREEN}${BOLD}✔  GDFP is running on ${CFG_LISTEN_HOST}:${CFG_LISTEN_PORT}${RESET}"
        else
            echo -e "  ${RED}Service failed to start. Check logs with option 4.${RESET}"
        fi
    fi

    echo ""
    echo -e "  ${GREEN}${BOLD}Installation complete!${RESET}"
    echo ""
    echo -e "  ${DIM}Proxy address : ${WHITE}${CFG_LISTEN_HOST}:${CFG_LISTEN_PORT}${RESET}"
    echo -e "  ${DIM}Config file   : ${WHITE}${CONFIG_FILE}${RESET}"
    echo -e "  ${DIM}Log file      : ${WHITE}${LOG_FILE}${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPTION 3 — Generate Xray Outbound Config
# ═══════════════════════════════════════════════════════════════════════════════
generate_xray_config() {
    show_header
    echo -e "  ${BOLD}[3] Generate Xray HTTP Outbound Config${RESET}"
    echo ""

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo -e "  ${RED}config.json not found. Please install GDFP first (option 2).${RESET}"
        pause; return
    fi

    # Read values from config
    read_cfg() {
        python3 -c "import json; d=json.load(open('${CONFIG_FILE}')); print(d.get('$1','$2'))" 2>/dev/null
    }

    LOCAL_HOST=$(read_cfg "listen_host" "127.0.0.1")
    LOCAL_PORT=$(read_cfg "listen_port" "8085")

    echo -e "  Reading config: ${DIM}${LOCAL_HOST}:${LOCAL_PORT}${RESET}"
    echo ""

    XRAY_JSON=$(cat <<EOF
{
  "tag": "gdfp-http-proxy",
  "protocol": "http",
  "settings": {
    "servers": [
      {
        "address": "${LOCAL_HOST}",
        "port": ${LOCAL_PORT}
      }
    ]
  }
}
EOF
)

    echo -e "  ${BOLD}${WHITE}Xray Outbound Block (HTTP proxy):${RESET}"
    echo ""
    echo -e "${CYAN}${XRAY_JSON}${RESET}"
    echo ""
    hr

    # Save to file
    OUTFILE="${INSTALL_DIR}/xray_outbound.json"
    echo "${XRAY_JSON}" > "${OUTFILE}"
    echo -e "  ${GREEN}✔  Saved to: ${OUTFILE}${RESET}"
    echo ""
    echo -e "  ${DIM}Add the above block inside the ${WHITE}\"outbounds\"${DIM} array in your Xray config.${RESET}"
    echo -e "  ${DIM}Then route traffic through tag: ${WHITE}gdfp-http-proxy${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPTION 4 — Status & Logs
# ═══════════════════════════════════════════════════════════════════════════════
status_logs_menu() {
    while true; do
        show_header
        echo -e "  ${BOLD}[4] Status & Logs${RESET}"
        echo ""

        # Service status
        if is_running; then
            echo -e "  Service   : ${GREEN}${BOLD}Active (running)${RESET}"
        else
            echo -e "  Service   : ${RED}${BOLD}Inactive / Stopped${RESET}"
        fi

        if is_installed; then
            echo -e "  Installed : ${GREEN}${BOLD}Yes${RESET}  ${DIM}(${INSTALL_DIR})${RESET}"
        else
            echo -e "  Installed : ${RED}${BOLD}No${RESET}"
        fi

        if [[ -f "${CONFIG_FILE}" ]]; then
            PROXY_ADDR=$(get_proxy_addr)
            echo -e "  Proxy     : ${CYAN}${PROXY_ADDR}${RESET}"
            echo -e "  Config    : ${DIM}${CONFIG_FILE}${RESET}"
        fi

        echo ""
        hr
        echo -e "   ${CYAN}1)${RESET}  Show last 50 log lines"
        echo -e "   ${CYAN}2)${RESET}  Follow live log (Ctrl+C to stop)"
        echo -e "   ${CYAN}3)${RESET}  Start proxy"
        echo -e "   ${CYAN}4)${RESET}  Stop proxy"
        echo -e "   ${CYAN}5)${RESET}  Restart proxy"
        echo -e "   ${CYAN}6)${RESET}  Show systemd service status"
        echo -e "   ${RED}0)${RESET}  Back to main menu"
        echo ""
        hr
        echo -ne "  ${BOLD}Select: ${RESET}"
        read -r sub_choice

        case "${sub_choice}" in
            1)
                echo ""
                if [[ -f "${LOG_FILE}" ]]; then
                    echo -e "  ${DIM}Last 50 lines of ${LOG_FILE}:${RESET}"
                    echo ""
                    tail -50 "${LOG_FILE}"
                else
                    echo -e "  ${YELLOW}Log file not found: ${LOG_FILE}${RESET}"
                fi
                pause
                ;;
            2)
                echo ""
                echo -e "  ${DIM}Following log (Ctrl+C to stop)...${RESET}"
                echo ""
                if [[ -f "${LOG_FILE}" ]]; then
                    tail -f "${LOG_FILE}"
                else
                    journalctl -u "${SERVICE_NAME}" -f
                fi
                ;;
            3)
                echo ""
                systemctl start "${SERVICE_NAME}"
                sleep 1
                is_running && echo -e "  ${GREEN}✔  Proxy started.${RESET}" || echo -e "  ${RED}Failed to start.${RESET}"
                pause
                ;;
            4)
                echo ""
                systemctl stop "${SERVICE_NAME}"
                echo -e "  ${YELLOW}Proxy stopped.${RESET}"
                pause
                ;;
            5)
                echo ""
                systemctl restart "${SERVICE_NAME}"
                sleep 1
                is_running && echo -e "  ${GREEN}✔  Proxy restarted.${RESET}" || echo -e "  ${RED}Failed to restart.${RESET}"
                pause
                ;;
            6)
                echo ""
                systemctl status "${SERVICE_NAME}" --no-pager
                pause
                ;;
            0|"")
                return
                ;;
            *)
                echo -e "  ${RED}Invalid option.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPTION 5 — Uninstall / Disable
# ═══════════════════════════════════════════════════════════════════════════════
uninstall() {
    show_header
    echo -e "  ${BOLD}[5] Uninstall / Disable GDFP${RESET}"
    echo ""
    echo -e "  ${RED}${BOLD}WARNING:${RESET} This will remove all GDFP files and the systemd service."
    echo ""
    echo -ne "  Are you sure? Type ${BOLD}YES${RESET} to confirm: "
    read -r confirm
    if [[ "${confirm}" != "YES" ]]; then
        echo -e "  ${YELLOW}Cancelled.${RESET}"
        pause; return
    fi

    echo ""
    echo -e "  ${CYAN}Stopping service...${RESET}"
    systemctl stop "${SERVICE_NAME}" 2>/dev/null
    systemctl disable "${SERVICE_NAME}" 2>/dev/null

    echo -e "  ${CYAN}Removing service file...${RESET}"
    rm -f "${SERVICE_FILE}"
    systemctl daemon-reload

    echo -e "  ${CYAN}Removing installation directory...${RESET}"
    rm -rf "${INSTALL_DIR}"

    echo -e "  ${CYAN}Removing log file...${RESET}"
    rm -f "${LOG_FILE}"

    echo ""
    echo -e "  ${GREEN}✔  GDFP has been completely removed.${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════════════════════
# Root check
# ═══════════════════════════════════════════════════════════════════════════════
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root (or with sudo).${RESET}"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Main Loop
# ═══════════════════════════════════════════════════════════════════════════════
while true; do
    show_header
    show_menu
    read -r choice

    case "${choice}" in
        1) install_prerequisites ;;
        2) install_script ;;
        3) generate_xray_config ;;
        4) status_logs_menu ;;
        5) uninstall ;;
        0|q|Q|exit)
            echo ""
            echo -e "  ${DIM}Goodbye.${RESET}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "  ${RED}Invalid option, please try again.${RESET}"
            sleep 1
            ;;
    esac
done
