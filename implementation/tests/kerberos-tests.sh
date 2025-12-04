#!/bin/bash
# Kerberos test script
# RUN AS NORMAL USER (with access to kinit)

set -euo pipefail

REALM="IAM.LAB"
ADMIN_PRINCIPAL="admin@${REALM}"

echo "======================================"
echo " Kerberos test – kinit + klist"
echo "======================================"
echo
echo "Attempting to get ticket for: $ADMIN_PRINCIPAL"
echo "You will be prompted for admin password."
echo

if kinit admin; then
  echo
  echo "kinit admin – SUCCESS"
else
  echo "kinit admin – FAILED"
  exit 1
fi

echo
echo "Current Kerberos tickets (klist):"
if klist; then
  echo
  echo "Kerberos test finished successfully."
else
  echo "klist failed."
  exit 1
fi