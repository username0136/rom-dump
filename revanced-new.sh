#!/usr/bin/env bash
# Standalone: re-clones vendor/revanced (relative to CWD) and processes RV prebuilts.
# Run from the rom root.
set -euo pipefail

YT_URL="${YT_URL:-https://github.com/PixelLineage/rv/releases/download/5/youtube-revanced-module-v20.51.39-all.zip}"
YTMUSIC_URL="${YTMUSIC_URL:-https://github.com/PixelLineage/rv/releases/download/5/music-revanced-module-v9.15.51-arm64-v8a.zip}"

VENDOR="$PWD/vendor/revanced"

# wipe and re-clone
rm -rf "$VENDOR"
mkdir -p "$(dirname "$VENDOR")"
git clone https://github.com/PixelLineage/vendor_revanced "$VENDOR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

place() {
    local zip_url="$1" app_dest="$2" patched_dest="$3"
    local work="$TMP/$(basename "$app_dest" .apk)"
    mkdir -p "$work"

    echo "[*] fetching $zip_url"
    curl -fsSL "$zip_url" -o "$work.zip"
    unzip -q "$work.zip" -d "$work"

    local main_apk base_apk
    main_apk=$(find "$work" -maxdepth 2 -name '*.apk' ! -name 'base.apk' -print -quit)
    base_apk=$(find "$work" -maxdepth 2 -name 'base.apk' -print -quit)

    if [ -z "$main_apk" ] || [ -z "$base_apk" ]; then
        echo "error: could not locate main apk or base.apk in $zip_url" >&2
        ls -la "$work" >&2
        exit 1
    fi

    install -D -m 644 "$main_apk" "$VENDOR/$app_dest"
    install -D -m 644 "$base_apk" "$VENDOR/$patched_dest"
    echo "[+] placed $(basename "$main_apk") -> $app_dest and base.apk -> $patched_dest"
}

place "$YT_URL" \
      "common/product/app/YouTube/YouTube.apk" \
      "common/product/etc/rv/YouTube_patched.apk"

place "$YTMUSIC_URL" \
      "common/product/app/YTMusic/YTMusic.apk" \
      "common/product/etc/rv/YTMusic_patched.apk"

echo "[*] running extract-libs.sh"
( cd "$VENDOR" && bash extract-libs.sh )

echo "[done] revanced prebuilts processed"
