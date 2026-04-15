#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/username0136/rom-dump"
SRC="$HOME/rom-dump"

# git identity
git config --global user.email "quick@disroot.org"
git config --global user.name  "Quick"

# clone (or update) this repo
if [ -d "$SRC/.git" ]; then
    git -C "$SRC" pull --ff-only
else
    git clone "$REPO_URL" "$SRC"
fi

# launch fish from .bashrc for interactive shells (works with byobu)
FISH="$(command -v fish 2>/dev/null || true)"
if [ -z "$FISH" ]; then
    echo "warning: fish not found — skipping shell config" >&2
elif ! grep -qs 'exec fish' "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" <<'EOF'

# launch fish for interactive shells (byobu-compatible)
if [[ $- == *i* ]] && command -v fish &>/dev/null; then
    exec fish
fi
EOF
fi

# install bin scripts
mkdir -p "$HOME/bin"
install -m 755 "$SRC/bin/crbuild"   "$HOME/bin/crbuild"
install -m 755 "$SRC/bin/crbuilder" "$HOME/bin/crbuilder"
install -m 755 "$SRC/bin/crstat"    "$HOME/bin/crstat"
install -m 755 "$SRC/bin/ksync"     "$HOME/bin/ksync"

# download repo tool
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
chmod a+x "$HOME/bin/repo"

# ensure ~/bin is on PATH for bash (fish picks it up via ~/bin automatically)
if ! grep -qs 'HOME/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi

# alias code -> code-server in bash
if ! grep -qs 'alias code=' "$HOME/.bashrc"; then
    echo "alias code='code-server'" >> "$HOME/.bashrc"
fi

# alias code -> code-server in fish
mkdir -p "$HOME/.config/fish"
if ! grep -qs 'alias code' "$HOME/.config/fish/config.fish" 2>/dev/null; then
    echo "alias code='code-server'" >> "$HOME/.config/fish/config.fish"
fi

# install crbuild user service
mkdir -p "$HOME/.config/systemd/user"
install -m 644 "$SRC/crbuild.service" "$HOME/.config/systemd/user/crbuild.service"
systemctl --user daemon-reload

# clone LineageOS sources
if [ ! -d "$HOME/los/.repo" ]; then
    mkdir -p "$HOME/los"
    cd "$HOME/los"
    "$HOME/bin/repo" init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
    "$HOME/bin/repo" sync --force-sync --force-checkout --retry-fetches=128 --no-tags --no-clone-bundle -j128
fi

# clone device / kernel / vendor trees into ~/los
clone_into() {
    local url="$1" dest="$2" branch="${3:-}"
    local full="$HOME/los/$dest"
    if [ -d "$full/.git" ]; then
        echo "skip $dest (exists)"
        return
    fi
    mkdir -p "$(dirname "$full")"
    if [ -n "$branch" ]; then
        git clone --depth 1 --branch "$branch" "$url" "$full"
    else
        git clone "$url" "$full"
    fi
}

KERNEL_DIR="$HOME/los/kernel/xiaomi/sm8250"
if [ ! -d "$KERNEL_DIR/.git" ]; then
    mkdir -p "$(dirname "$KERNEL_DIR")"
    git clone --depth 50 https://github.com/PixelLineage/kernel_xiaomi_sm8250 "$KERNEL_DIR"
    git -C "$KERNEL_DIR" submodule init
    git -C "$KERNEL_DIR" submodule update
else
    echo "skip kernel/xiaomi/sm8250 (exists)"
fi

clone_into https://github.com/PixelLineage/device_xiaomi_sm8250-common device/xiaomi/sm8250-common
clone_into https://github.com/PixelLineage/device_xiaomi_munch         device/xiaomi/munch
clone_into https://github.com/PixelLineage/device_xiaomi_alioth        device/xiaomi/alioth

clone_into https://gitlab.com/munch-qwik/vt/1_vendor_xiaomi_munch         vendor/xiaomi/munch         q2
clone_into https://gitlab.com/munch-qwik/vt/1_vendor_xiaomi_munch         vendor/xiaomi/alioth        alioth-q2
clone_into https://gitlab.com/munch-qwik/vt/1_vendor_xiaomi_sm8250-common vendor/xiaomi/sm8250-common q2

# fetch prebuilt clang-stable for kernel builds
if [ ! -x "$HOME/los/prebuilts/clang/kernel/linux-x86/clang-stable/bin/clang" ]; then
    bash "$SRC/fetch-clang.sh" "$HOME/los"
fi

# fetch PixelLineage setup script
curl -fsSL https://raw.githubusercontent.com/PixelLineage/res/refs/heads/main/setup.sh \
    -o "$HOME/los/setup.sh"
chmod +x "$HOME/los/setup.sh"

echo "done."
