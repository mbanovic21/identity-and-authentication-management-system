#!/bin/bash
# IPA user test script
# RUN AS USER WITH IPA PRIVILEGES (after: kinit admin)

set -euo pipefail

# Check if we have a Kerberos ticket
if ! klist >/dev/null 2>&1; then
  echo "No Kerberos ticket found. Run: kinit admin"
  exit 1
fi

echo "======================================"
echo " IPA user test – create test user"
echo "======================================"
echo

read -rp "Enter username for test (e.g. testuser1): " TESTUSER

echo
echo "[1/4] Creating user: $TESTUSER"
if ! ipa user-add "$TESTUSER" --first=Test --last=User; then
  echo "Could not create user (maybe already exists?)."
  exit 1
fi

echo
echo "[2/4] Trying to set WEAK password (expected: FAIL)"
echo "Command: ipa passwd $TESTUSER"
echo "Try something weak like 'lozinka' or '123456'."
ipa passwd "$TESTUSER" && \
  echo "WARNING: Weak password accepted (policy might not be enforced)." || \
  echo "OK: Weak password rejected."

echo
echo "[3/4] Now set STRONG password (expected: SUCCESS)"
echo "Command: ipa passwd $TESTUSER"
if ! ipa passwd "$TESTUSER"; then
  echo "Failed to set strong password – check password policy configuration."
  exit 1
fi

echo
echo "[4/4] Checking that user exists:"
if ipa user-show "$TESTUSER"; then
  echo
  echo "User test for $TESTUSER completed successfully."
  echo "You can further test lockout by intentionally failing kinit $TESTUSER several times."
else
  echo "User $TESTUSER not found – something went wrong."
  exit 1
fi