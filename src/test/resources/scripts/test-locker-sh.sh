#!/bin/bash
# Integration test for the locker.sh wrapper.
# Usage: test-locker-sh.sh <path-to-locker.jar> <path-to-locker.sh>
# Runs on Linux/macOS CI; uses the system "java" (no bundled JRE required).
set -uo pipefail

JAR=$1
SCRIPT=$2
KEY="integration-test-key"
PLAIN="The quick brown fox jumps over the lazy dog"
APPEND="Another secret line"

pass=0
fail=0
check() {
    if [ "$1" = "$2" ]; then
        echo "[PASS] $3"; pass=$((pass + 1))
    else
        echo "[FAIL] $3 (got [$2], expected [$1])"; fail=$((fail + 1))
    fi
}

tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT
cp "${JAR}"    "${tmp}/locker.jar"
cp "${SCRIPT}" "${tmp}/locker.sh"
chmod +x "${tmp}/locker.sh"
: > "${tmp}/locker.dat"

# Test 1: encrypt -> decrypt (default file)
printf '%s' "${PLAIN}" | "${tmp}/locker.sh" -e "${KEY}"
check "${PLAIN}" "$("${tmp}/locker.sh" -d "${KEY}")" "encrypt -> decrypt (default file)"

# Test 2: append -> decrypt keeps a single newline between entries
printf '%s' "${APPEND}" | "${tmp}/locker.sh" -a "${KEY}"
check "$(printf '%s\n%s' "${PLAIN}" "${APPEND}")" "$("${tmp}/locker.sh" -d "${KEY}")" \
    "append -> decrypt (single newline between entries)"

# Test 3: wrong key is rejected
if "${tmp}/locker.sh" -d "wrong-key" >/dev/null 2>&1; then
    echo "[FAIL] wrong key is rejected"; fail=$((fail + 1))
else
    echo "[PASS] wrong key is rejected"; pass=$((pass + 1))
fi

# Test 4: custom file via -f is independent from the default file
custom="${tmp}/custom.dat"
: > "${custom}"
printf '%s' "${PLAIN}" | "${tmp}/locker.sh" -e "${KEY}" -f "${custom}"
check "${PLAIN}" "$("${tmp}/locker.sh" -d "${KEY}" -f "${custom}")" "encrypt -> decrypt (custom file)"

# Test 5: invocation through a symlink must resolve the real script dir, so the
# bundled jar next to the real locker.sh is found (regression test for the
# /usr/local/bin/locker -> /opt/locker/locker.sh install layout).
mkdir -p "${tmp}/bin"
ln -s "${tmp}/locker.sh" "${tmp}/bin/locker"
printf '%s' "${PLAIN}" | "${tmp}/bin/locker" -e "${KEY}"
check "${PLAIN}" "$("${tmp}/bin/locker" -d "${KEY}")" "invocation via symlink resolves the real script dir"

echo ""
echo "locker.sh integration: ${pass} passed, ${fail} failed"
[ "${fail}" -eq 0 ]
