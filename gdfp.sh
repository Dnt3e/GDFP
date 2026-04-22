#!/usr/bin/env bash
# GDFP - Google Domain Fronting Proxy Installer
# Creator: Dnt3e | Original project: masterking32/MasterHttpRelayVPN
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
        local host port socks5_port socks5_enabled
        host=$(python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('listen_host','127.0.0.1'))" 2>/dev/null)
        port=$(python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('listen_port',8085))" 2>/dev/null)
        socks5_enabled=$(python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('socks5_enabled',True))" 2>/dev/null)
        socks5_port=$(python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('socks5_port',1080))" 2>/dev/null)
        if [[ "${socks5_enabled}" == "True" ]]; then
            echo "HTTP ${host:-127.0.0.1}:${port:-8085} | SOCKS5 ${host:-127.0.0.1}:${socks5_port:-1080}"
        else
            echo "HTTP ${host:-127.0.0.1}:${port:-8085}"
        fi
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
    echo -e "  ${WHITE}by ${BOLD}Dnt3e${RESET}   ${DIM}(original project: masterking32/MasterHttpRelayVPN)${RESET}"
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

    # Check unzip / curl / wget
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
        echo ""
        echo -e "  ${DIM}Installed packages provide:${RESET}"
        echo -e "  ${DIM}  • cryptography  — MITM TLS interception (required for HTTPS)${RESET}"
        echo -e "  ${DIM}  • h2            — HTTP/2 multiplexing (faster relay)${RESET}"
        echo -e "  ${DIM}  • brotli        — Content-Encoding: br decompression${RESET}"
        echo -e "  ${DIM}  • zstandard     — Content-Encoding: zstd decompression${RESET}"
    else
        echo -e "  ${YELLOW}GDFP not installed yet — requirements.txt not found.${RESET}"
        echo -e "  ${DIM}Please run option 2 (Install GDFP) first, or install manually.${RESET}"
        echo ""
        echo -e "  ${DIM}Manual install after option 2:${RESET}"
        echo -e "  ${DIM}  pip3 install cryptography h2 brotli zstandard${RESET}"
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

    # ── MANDATORY: script_id(s) ───────────────────────────────────────────────
    echo -e "  ${BOLD}Script / Deployment ID(s)${RESET}  ${RED}(required)${RESET}"
    echo -e "  ${DIM}Google Apps Script → Deploy → Manage deployments → copy the Deployment ID.${RESET}"
    echo -e "  ${DIM}You can enter multiple IDs separated by commas for load balancing.${RESET}"
    echo -e "  ${DIM}(Multiple deployments must all use the same auth_key)${RESET}"
    echo ""
    while true; do
        echo -ne "  script_id(s): "
        read -r CFG_SCRIPT_INPUT
        CFG_SCRIPT_INPUT="${CFG_SCRIPT_INPUT// /}"
        if [[ -z "${CFG_SCRIPT_INPUT}" ]]; then
            echo -e "  ${RED}script_id cannot be empty.${RESET}"
        else
            break
        fi
    done
    echo ""

    # ── MANDATORY: auth_key ───────────────────────────────────────────────────
    echo -e "  ${BOLD}Auth Key (secret password)${RESET}  ${RED}(required)${RESET}"
    echo -e "  ${DIM}Must match AUTH_KEY in your Google Apps Script Code.gs.${RESET}"
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
    if ! [[ "${CFG_LISTEN_PORT}" =~ ^[0-9]+$ ]] || (( CFG_LISTEN_PORT < 1 || CFG_LISTEN_PORT > 65535 )); then
        echo -e "  ${YELLOW}Invalid port, using default 8085.${RESET}"
        CFG_LISTEN_PORT=8085
    fi

    echo ""
    echo -e "  ${BOLD}SOCKS5 Settings${RESET}  ${DIM}(built-in SOCKS5 proxy)${RESET}"
    echo ""

    echo -ne "  Enable SOCKS5 proxy? [Y/n]: "
    read -r CFG_SOCKS5_ENABLED_INPUT
    CFG_SOCKS5_ENABLED_INPUT="${CFG_SOCKS5_ENABLED_INPUT:-y}"
    if [[ "${CFG_SOCKS5_ENABLED_INPUT,,}" == "y" ]]; then
        CFG_SOCKS5_ENABLED="true"
        echo -ne "  socks5_port   [1080]: "
        read -r CFG_SOCKS5_PORT
        CFG_SOCKS5_PORT="${CFG_SOCKS5_PORT:-1080}"
        if ! [[ "${CFG_SOCKS5_PORT}" =~ ^[0-9]+$ ]] || (( CFG_SOCKS5_PORT < 1 || CFG_SOCKS5_PORT > 65535 )); then
            echo -e "  ${YELLOW}Invalid port, using default 1080.${RESET}"
            CFG_SOCKS5_PORT=1080
        fi
    else
        CFG_SOCKS5_ENABLED="false"
        CFG_SOCKS5_PORT=1080
    fi

    echo ""
    echo -e "  ${BOLD}Relay Performance${RESET}"
    echo ""
    echo -e "  ${DIM}parallel_relay: Number of simultaneous relay connections (1-5).${RESET}"
    echo -ne "  parallel_relay [1]: "
    read -r CFG_PARALLEL_RELAY
    CFG_PARALLEL_RELAY="${CFG_PARALLEL_RELAY:-1}"
    if ! [[ "${CFG_PARALLEL_RELAY}" =~ ^[0-9]+$ ]] || (( CFG_PARALLEL_RELAY < 1 || CFG_PARALLEL_RELAY > 5 )); then
        echo -e "  ${YELLOW}Invalid value, using default 1.${RESET}"
        CFG_PARALLEL_RELAY=1
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

    python3 - <<PYEOF
import json, sys

script_input = "${CFG_SCRIPT_INPUT}".strip()
# Support comma-separated multiple script IDs
if "," in script_input:
    script_ids = [s.strip() for s in script_input.split(",") if s.strip()]
    script_key = "script_ids"
    script_val = script_ids
else:
    script_key = "script_id"
    script_val = script_input

cfg = {
    "mode": "apps_script",
    "google_ip": "${CFG_GOOGLE_IP}",
    "front_domain": "${CFG_FRONT_DOMAIN}",
    script_key: script_val,
    "auth_key": "${CFG_AUTH_KEY}",
    "listen_host": "${CFG_LISTEN_HOST}",
    "listen_port": int("${CFG_LISTEN_PORT}"),
    "socks5_enabled": "${CFG_SOCKS5_ENABLED}" == "true",
    "socks5_port": int("${CFG_SOCKS5_PORT}"),
    "parallel_relay": int("${CFG_PARALLEL_RELAY}"),
    "log_level": "${CFG_LOG_LEVEL}",
    "verify_ssl": "${CFG_VERIFY_SSL}" == "true",
    "block_hosts": [],
    "bypass_hosts": ["localhost", ".local", ".lan", ".home.arpa"],
    "direct_google_exclude": [
        "gemini.google.com",
        "aistudio.google.com",
        "notebooklm.google.com",
        "labs.google.com",
        "meet.google.com",
        "accounts.google.com",
        "ogs.google.com",
        "mail.google.com",
        "calendar.google.com",
        "drive.google.com",
        "docs.google.com",
        "chat.google.com"
    ],
    "direct_google_allow": [
        "www.google.com",
        "safebrowsing.google.com"
    ],
    "hosts": {}
}

with open("${CONFIG_FILE}", "w") as f:
    json.dump(cfg, f, indent=2)

print("  Config written to ${CONFIG_FILE}")
PYEOF

    echo ""
    # ── Create systemd service ─────────────────────────────────────────────────
    PYTHON_BIN=$(command -v python3)
    echo -e "  ${CYAN}Creating systemd service...${RESET}"

    SOCKS5_FLAG=""
    [[ "${CFG_SOCKS5_ENABLED}" == "false" ]] && SOCKS5_FLAG="--disable-socks5"

    cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=GDFP - Google Domain Fronting Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${PYTHON_BIN} ${INSTALL_DIR}/main.py -c ${CONFIG_FILE} ${SOCKS5_FLAG}
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

    # ── Install CA certificate ─────────────────────────────────────────────────
    echo -ne "  Install MITM CA certificate now? [Y/n]: "
    read -r install_cert_now
    install_cert_now="${install_cert_now:-y}"
    if [[ "${install_cert_now,,}" == "y" ]]; then
        echo -e "  ${CYAN}Installing CA certificate (apps_script mode requires MITM for HTTPS)...${RESET}"
        python3 "${INSTALL_DIR}/main.py" -c "${CONFIG_FILE}" --install-cert 2>&1 | tail -5
        echo ""
        echo -e "  ${DIM}If auto-install failed, manually install: ${WHITE}${INSTALL_DIR}/ca/ca.crt${RESET}"
        echo -e "  ${DIM}Firefox users: also import it in Settings → Privacy → Certificates.${RESET}"
    fi
    echo ""

    # ── Start service ─────────────────────────────────────────────────────────
    echo -ne "  Start GDFP proxy now? [Y/n]: "
    read -r start_now
    start_now="${start_now:-y}"
    if [[ "${start_now,,}" == "y" ]]; then
        systemctl start "${SERVICE_NAME}"
        sleep 1
        if is_running; then
            echo -e "  ${GREEN}${BOLD}✔  GDFP is running!${RESET}"
            echo -e "  ${DIM}HTTP  proxy : ${WHITE}${CFG_LISTEN_HOST}:${CFG_LISTEN_PORT}${RESET}"
            [[ "${CFG_SOCKS5_ENABLED}" == "true" ]] && \
                echo -e "  ${DIM}SOCKS5 proxy: ${WHITE}${CFG_LISTEN_HOST}:${CFG_SOCKS5_PORT}${RESET}"
        else
            echo -e "  ${RED}Service failed to start. Check logs with option 4.${RESET}"
        fi
    fi

    echo ""
    echo -e "  ${GREEN}${BOLD}Installation complete!${RESET}"
    echo ""
    echo -e "  ${DIM}HTTP proxy  : ${WHITE}${CFG_LISTEN_HOST}:${CFG_LISTEN_PORT}${RESET}"
    [[ "${CFG_SOCKS5_ENABLED}" == "true" ]] && \
        echo -e "  ${DIM}SOCKS5 proxy: ${WHITE}${CFG_LISTEN_HOST}:${CFG_SOCKS5_PORT}${RESET}"
    echo -e "  ${DIM}Config file : ${WHITE}${CONFIG_FILE}${RESET}"
    echo -e "  ${DIM}Log file    : ${WHITE}${LOG_FILE}${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPTION 3 — Generate Xray Outbound Config
# ═══════════════════════════════════════════════════════════════════════════════
generate_xray_config() {
    show_header
    echo -e "  ${BOLD}[3] Generate Xray Outbound Config${RESET}"
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
    SOCKS5_ENABLED=$(read_cfg "socks5_enabled" "True")
    SOCKS5_PORT=$(read_cfg "socks5_port" "1080")

    echo -e "  ${DIM}HTTP proxy  : ${LOCAL_HOST}:${LOCAL_PORT}${RESET}"
    if [[ "${SOCKS5_ENABLED}" == "True" ]]; then
        echo -e "  ${DIM}SOCKS5 proxy: ${LOCAL_HOST}:${SOCKS5_PORT}${RESET}"
    fi
    echo ""

    # ── Protocol Selection ────────────────────────────────────────────────────
    echo -e "  ${BOLD}Select Xray outbound protocol:${RESET}"
    echo ""
    echo -e "   ${CYAN}1)${RESET} ${BOLD}HTTP${RESET}   — Standard HTTP proxy outbound  ${DIM}(port ${LOCAL_PORT})${RESET}"
    if [[ "${SOCKS5_ENABLED}" == "True" ]]; then
        echo -e "   ${CYAN}2)${RESET} ${BOLD}SOCKS5${RESET} — SOCKS5 proxy outbound         ${DIM}(port ${SOCKS5_PORT})${RESET}"
    else
        echo -e "   ${DIM}2)  SOCKS5 — disabled in config${RESET}"
    fi
    echo ""
    echo -e "  ${DIM}Note: For Telegram, HTTP proxy is recommended (SOCKS5 may not work).${RESET}"
    echo ""

    while true; do
        echo -ne "  Protocol [1-2, default=1]: "
        read -r proto_choice
        proto_choice="${proto_choice:-1}"
        case "${proto_choice}" in
            1)
                XRAY_PROTOCOL="http"
                XRAY_PORT="${LOCAL_PORT}"
                XRAY_TAG="gdfp-http-proxy"
                break
                ;;
            2)
                if [[ "${SOCKS5_ENABLED}" != "True" ]]; then
                    echo -e "  ${RED}SOCKS5 is disabled in config. Enable it first (reinstall option 2).${RESET}"
                else
                    XRAY_PROTOCOL="socks"
                    XRAY_PORT="${SOCKS5_PORT}"
                    XRAY_TAG="gdfp-socks5-proxy"
                    break
                fi
                ;;
            *)
                echo -e "  ${RED}Invalid choice. Enter 1 or 2.${RESET}"
                ;;
        esac
    done

    echo ""

    # ── Build JSON ────────────────────────────────────────────────────────────
    if [[ "${XRAY_PROTOCOL}" == "http" ]]; then
        XRAY_JSON=$(cat <<EOF
{
  "tag": "${XRAY_TAG}",
  "protocol": "http",
  "settings": {
    "servers": [
      {
        "address": "${LOCAL_HOST}",
        "port": ${XRAY_PORT}
      }
    ]
  }
}
EOF
)
    else
        XRAY_JSON=$(cat <<EOF
{
  "tag": "${XRAY_TAG}",
  "protocol": "socks",
  "settings": {
    "servers": [
      {
        "address": "${LOCAL_HOST}",
        "port": ${XRAY_PORT},
        "level": 0
      }
    ]
  }
}
EOF
)
    fi

    echo -e "  ${BOLD}${WHITE}Xray Outbound Block (${XRAY_PROTOCOL^^} proxy):${RESET}"
    echo ""
    echo -e "${CYAN}${XRAY_JSON}${RESET}"
    echo ""
    hr

    # Save to file
    OUTFILE="${INSTALL_DIR}/xray_outbound_${XRAY_PROTOCOL}.json"
    echo "${XRAY_JSON}" > "${OUTFILE}"
    echo -e "  ${GREEN}✔  Saved to: ${OUTFILE}${RESET}"
    echo ""
    echo -e "  ${DIM}Add the above block inside the ${WHITE}\"outbounds\"${DIM} array in your Xray config.${RESET}"
    echo -e "  ${DIM}Then route traffic through tag: ${WHITE}${XRAY_TAG}${RESET}"
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
        echo -e "   ${CYAN}7)${RESET}  Install / Reinstall CA Certificate"
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
            7)
                echo ""
                if is_installed; then
                    echo -e "  ${CYAN}Installing MITM CA certificate...${RESET}"
                    python3 "${INSTALL_DIR}/main.py" -c "${CONFIG_FILE}" --install-cert 2>&1 | tail -10
                    echo ""
                    echo -e "  ${DIM}Certificate file: ${WHITE}${INSTALL_DIR}/ca/ca.crt${RESET}"
                    echo -e "  ${DIM}Firefox users: import manually in Settings → Privacy → Certificates.${RESET}"
                else
                    echo -e "  ${RED}GDFP is not installed. Run option 2 first.${RESET}"
                fi
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
    echo -e "  ${DIM}Note: The MITM CA certificate may still be installed in your browser/OS.${RESET}"
    echo -e "  ${DIM}Remove it manually if needed.${RESET}"
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
