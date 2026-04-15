# rom-dump

LineageOS 23.2 build bootstrap for Xiaomi **munch** / **alioth**.

## Install

Run from `~` on the build server (no sudo needed):

```bash
curl -fsSL https://raw.githubusercontent.com/username0136/rom-dump/main/main.sh | bash
```

[main.sh](main.sh) installs fish as login shell, drops helpers into `~/bin`, installs `crbuild.service` as a user unit, then `repo sync`s LineageOS into `~/los` along with device/kernel/vendor trees, clang-stable, and PixelLineage's `setup.sh`.

## Usage

```fish
crbuild     # toggle build service on/off
crstat      # tail the build log
```

## Files

- [main.sh](main.sh) — bootstrap installer
- [fetch-clang.sh](fetch-clang.sh) — pulls latest AOSP `clang-stable`
- [crbuild.service](crbuild.service) — systemd user unit
- [bin/crbuilder](bin/crbuilder) — `lunch` + `m bacon` driver
- [bin/crbuild](bin/crbuild), [bin/crstat](bin/crstat) — start/stop toggle, log tail
