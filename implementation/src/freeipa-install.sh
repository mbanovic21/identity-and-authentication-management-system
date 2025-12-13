#!/bin/bash
# FreeIPA server installation helper script
# OS: Rocky Linux 9 (RHEL-like)
# RUN AS ROOT (sudo su - or sudo ./freeipa-install.sh)

set -euo pipefail

### CONFIG VARIABLES – ADJUST TO YOUR ENVIRONMENT ###
HOSTNAME_FQDN="ipa1.iam.lab"   # Server FQDN
DOMAIN="iam.lab"               # DNS domain
REALM="IAM.LAB"                # Kerberos realm (UPPERCASE)
IP_ADDR="192.168.1.220"        # FreeIPA server Host-only IP
TIMEZONE="Europe/Zagreb"       # Timezone

### FUNCTIONS ###

check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script as root (sudo su - or sudo $0)"
    exit 1
  fi
}

set_hostname() {
  echo "[1/7] Setting hostname to: $HOSTNAME_FQDN"
  hostnamectl set-hostname "$HOSTNAME_FQDN"
  echo "Current hostname:"
  hostnamectl
}

configure_timezone_ntp() {
  echo "[2/7] Configuring timezone and NTP (chrony)..."
  timedatectl set-timezone "$TIMEZONE"
  dnf install -y chrony
  systemctl enable --now chronyd
  echo "Current time and NTP status:"
  timedatectl
}

update_system() {
  echo "[3/7] Updating system packages..."
  dnf update -y
}

configure_hosts() {
  echo "[4/7] Configuring /etc/hosts..."
  # Remove any existing line for this hostname
  sed -i.bak "/$HOSTNAME_FQDN/d" /etc/hosts || true

  SHORT_HOSTNAME="${HOSTNAME_FQDN%%.*}"

  echo "$IP_ADDR   $HOSTNAME_FQDN   $SHORT_HOSTNAME" >> /etc/hosts
  echo "/etc/hosts now contains:"
  grep "$HOSTNAME_FQDN" /etc/hosts || true
}

install_freeipa_packages() {
  echo "[5/7] Installing FreeIPA server packages..."
  dnf install -y ipa-server ipa-server-dns
}

disable_firewalld_for_lab() {
  echo "[6/7] Disabling firewalld (lab only, not for production!)..."
  systemctl stop firewalld || true
  systemctl disable firewalld || true
}

run_ipa_server_install() {
  echo "[7/7] Running ipa-server-install..."
  echo "NOTE:"
  echo " - You will be asked for Directory Manager and admin passwords."
  echo " - Choose DNS forwarder (e.g. 8.8.8.8)."
  echo " - Check that domain, realm and hostname are correct."

  ipa-server-install \
    --setup-dns \
    --hostname="$HOSTNAME_FQDN" \
    --domain="$DOMAIN" \
    --realm="$REALM"

  echo "If you see 'The ipa-server-install command was successful' → installation finished OK."
}

### MAIN FLOW ###

check_root
set_hostname
configure_timezone_ntp
update_system
configure_hosts
install_freeipa_packages
disable_firewalld_for_lab
run_ipa_server_install

echo
echo "==============================================="
echo " FreeIPA server setup script finished."
echo " Next steps (manual):"
echo "  1) kinit admin"
echo "  2) klist"
echo "  3) ipa user-find"
echo "==============================================="
