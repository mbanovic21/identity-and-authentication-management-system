#!/bin/bash
# FreeIPA client setup script
# OS: Rocky Linux 9 (RHEL-like)
# RUN AS ROOT

set -euo pipefail

### CONFIG – ADJUST FOR YOUR ENVIRONMENT ###
IPA_SERVER_FQDN="ipa1.iam.lab"
IPA_SERVER_IP="192.168.1.220"
DOMAIN="iam.lab"
REALM="IAM.LAB"
TIMEZONE="Europe/Zagreb"

check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script as root (sudo su - or sudo $0)"
    exit 1
  fi
}

configure_timezone_ntp() {
  echo "[1/5] Configuring timezone and NTP (chrony)..."
  timedatectl set-timezone "$TIMEZONE"
  dnf install -y chrony
  systemctl enable --now chronyd
  echo "Current time and NTP status:"
  timedatectl
}

configure_hosts() {
  echo "[2/5] Adding FreeIPA server to /etc/hosts..."
  sed -i.bak "/$IPA_SERVER_FQDN/d" /etc/hosts || true
  SHORT_HOSTNAME="${IPA_SERVER_FQDN%%.*}"
  echo "$IPA_SERVER_IP   $IPA_SERVER_FQDN   $SHORT_HOSTNAME" >> /etc/hosts
  echo "/etc/hosts now contains:"
  grep "$IPA_SERVER_FQDN" /etc/hosts || true
}

install_client_packages() {
  echo "[3/5] Installing IPA client packages..."
  dnf install -y ipa-client sssd oddjob oddjob-mkhomedir adcli samba-common-tools
}

disable_firewalld_for_lab() {
  echo "[4/5] Disabling firewalld (lab only, not for production!)..."
  systemctl stop firewalld || true
  systemctl disable firewalld || true
}

run_ipa_client_install() {
  echo "[5/5] Running ipa-client-install..."
  echo "You will be asked for admin@$REALM password."
  ipa-client-install \
    --mkhomedir \
    --domain="$DOMAIN" \
    --server="$IPA_SERVER_FQDN" \
    --realm="$REALM"
}

check_root
configure_timezone_ntp
configure_hosts
install_client_packages
disable_firewalld_for_lab
run_ipa_client_install

echo
echo "==============================================="
echo " FreeIPA client setup script finished."
echo " Suggested tests:"
echo "  - id admin"
echo "  - id testuser   (if created on server)"
echo "  - su - testuser"
echo "==============================================="
