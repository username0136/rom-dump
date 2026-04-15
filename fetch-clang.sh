#!/usr/bin/env bash
#
# Fetches the latest "clang-stable" build referenced by AOSP's
# main-kernel branch and extracts it into:
#   prebuilts/clang/host/linux-x86/clang-stable
#
# Workflow:
#   1. Read the README.md page from main-kernel/clang-stable/ to discover
#      which clang-rNNNNNN snapshot it currently points at.
#      (HTML scrape — gitiles' ?format=TEXT is not always supported.)
#   2. Download that snapshot's .tgz from gitiles' +archive endpoint.
#   3. Extract into the destination directory.
#
# Usage: ./fetch-clang-stable.sh [DEST_ROOT]
#   DEST_ROOT defaults to the current directory.

set -euo pipefail

DEST_ROOT="${1:-$PWD}"
DEST="${DEST_ROOT}/prebuilts/clang/host/linux-x86/clang-stable"

BASE="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86"
README_URL="${BASE}/+/refs/heads/main-kernel/clang-stable/README.md"
ARCHIVE_BASE="${BASE}/+archive/refs/heads/main-kernel"

# --- 1. Discover current clang version --------------------------------------
echo "[*] Reading README to find current clang-stable target..."
README_HTML=$(curl -sSL "${README_URL}")

# README contains a line like:
#   "All contents in clang-stable are copies of clang-rNNNNNN[letter]."
# The version string survives HTML rendering as plain text, so just grep.
CLANG_VER=$(printf '%s' "${README_HTML}" | grep -oE 'clang-r[0-9]+[a-z]?' | head -n1)

if [[ -z "${CLANG_VER}" ]]; then
  echo "[!] Could not parse clang version from README page." >&2
  echo "    URL: ${README_URL}" >&2
  exit 1
fi

echo "[+] clang-stable currently points at: ${CLANG_VER}"

# --- 2. Download tarball ----------------------------------------------------
TARBALL="${CLANG_VER}.tgz"
DL_URL="${ARCHIVE_BASE}/${TARBALL}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

echo "[*] Downloading ${DL_URL}"
wget --show-progress -q -O "${TMPDIR}/${TARBALL}" "${DL_URL}"

# Sanity check: gitiles can serve HTML error pages with 200; verify gzip.
if ! gzip -t "${TMPDIR}/${TARBALL}" 2>/dev/null; then
  echo "[!] Downloaded file is not a valid gzip archive." >&2
  echo "    URL was: ${DL_URL}" >&2
  exit 1
fi

# --- 3. Extract to destination ----------------------------------------------
echo "[*] Wiping and recreating: ${DEST}"
rm -rf "${DEST}"
mkdir -p "${DEST}"

echo "[*] Extracting..."
# gitiles +archive tarballs contain the *contents* of the directory at
# the root of the archive (no top-level wrapper folder), so no
# --strip-components is needed.
tar -xzf "${TMPDIR}/${TARBALL}" -C "${DEST}"

# --- 4. Report --------------------------------------------------------------
echo "[✓] Installed ${CLANG_VER} at: ${DEST}"
if [[ -x "${DEST}/bin/clang" ]]; then
  "${DEST}/bin/clang" --version | head -n1
else
  echo "[!] Warning: ${DEST}/bin/clang not found after extraction." >&2
  exit 1
fi
