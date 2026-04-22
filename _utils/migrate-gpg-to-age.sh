#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(cd "$(dirname "$0")" && pwd)}"

RECIPIENTS=(
  "age1yubikey1qtcxpg7xtagh8kfgzp4qeeerht78s8h0cvlq2xjgffuh4dlde7mx5my5jzc"
  "age1yubikey1q2xmrh6ct89c27ndrw0w49whm29pqrnqtxpac2cnppytjd7xkjkdvy9dcqe"
  "age1efstcnvqlqwewp0c9du4snkdqt7g34c5hnsvc9ep02d8yue4xclq4qy3x6"
)

echo "=== GPG → Age Migration Script ==="
echo "Target: ${TARGET_DIR}"
echo "Recipients:"
printf '  %s\n' "${RECIPIENTS[@]}"
echo ""

mapfile -t ENCRYPTED_FILES < <(find "${TARGET_DIR}" -name '*.asc' -type f | sort)

if [ ${#ENCRYPTED_FILES[@]} -eq 0 ]; then
  echo "No .asc files found. Already migrated?"
  exit 0
fi

echo "Found ${#ENCRYPTED_FILES[@]} encrypted files to migrate:"
printf '  %s\n' "${ENCRYPTED_FILES[@]}"
echo ""

read -rp "Continue? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

FAILED=0

for ASC_FILE in "${ENCRYPTED_FILES[@]}"; do
  AGE_FILE="${ASC_FILE%.asc}.age"
  TMP_FILE=$(mktemp)

  echo "--- ${ASC_FILE##${TARGET_DIR}/} ---"

  if ! gpg -q -d "${ASC_FILE}" >"${TMP_FILE}" 2>/dev/null; then
    echo "  FAIL: GPG decryption failed"
    rm -f "${TMP_FILE}"
    FAILED=$((FAILED + 1))
    continue
  fi

  AGE_CMD=(age)
  for R in "${RECIPIENTS[@]}"; do
    AGE_CMD+=(-r "${R}")
  done
  AGE_CMD+=(-o "${AGE_FILE}" "${TMP_FILE}")

  if ! "${AGE_CMD[@]}"; then
    echo "  FAIL: Age encryption failed"
    rm -f "${TMP_FILE}"
    FAILED=$((FAILED + 1))
    continue
  fi

  rm -f "${TMP_FILE}"
  rm -f "${ASC_FILE}"

  echo "  OK → ${AGE_FILE##${TARGET_DIR}/}"
done

echo ""
echo "=== Migration complete ==="
if [ ${FAILED} -gt 0 ]; then
  echo "${FAILED} file(s) failed."
  exit 1
fi
