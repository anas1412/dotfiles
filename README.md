# dotfiles

Managed configs for my CachyOS (Arch Linux) KDE Plasma 6 desktop.

```
       /\        blackbox@blackbox
      /  \       -----------------
     /    \      OS         ➜  CachyOS x86_64
    /      \     Base       ➜  Arch Linux
   /   ,,   \    Kernel     ➜  Linux 7.0.5-2-cachyos
  /_-''    ''-_\  Packages   ➜  1425 (pacman)
                 Shell      ➜  fish 4.7.1
                 WM         ➜  KWin (Wayland)
                 Terminal   ➜  alacritty 0.17.0
                 CPU        ➜  Intel(R) Core(TM) i5-10300H (8) @ 4.50 GHz - 77.0°C
                 GPU 1      ➜  NVIDIA GeForce GTX 1650 - 54.0°C [Discrete]
                 GPU 2      ➜  Intel UHD Graphics @ 1.05 GHz [Integrated]
                 Memory     ➜  8.42 GiB / 15.39 GiB (55%)
```

![Desktop Screenshot](Screenshot.png)

## Requirements

- **Arch Linux** (CachyOS recommended)
- **Fish shell** (required for the scripts)
- **sudo** (for package installs during restore)
- **paru** (for AUR package restore)

## Quick start

Clone and run the menu:

```sh
git clone git@github.com:anas1412/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.fish
```

## Usage

### Menu-driven (recommended)

```
DOTFILES MANAGER - ANAS1412

Main menu:
  1) System        → Restore / Backup / Audit
  2) Maintenance   → Full / Update / Clean / Orphans / Journal / Snapshots / Flatpak
  3) Extras        → Install Opencode + OAC / Bluetooth Mic Fix / Auto Backup Timer
  4) Theme Info    → Display current KDE theme settings
  5) System Info   → Show system info (fastfetch)
  0) Exit
```

**System → Restore** lets you pick what to restore:
- **Full** — runs audit first, then packages + configs + themes
- **Configs only** — fish, KDE, terminals, fastfetch (no audit required)
- **Themes only** — custom theme archive + style vars (no audit required)

### Manual commands

| Action | Command |
|--------|---------|
| **Backup** | `fish scripts/backup.fish` |
| **Audit** | `fish scripts/audit.fish [--packages \| --configs \| --coverage \| --deps \| --drift \| --secrets \| --scripts]` |
| **Full restore** | `fish scripts/restore.fish --all` |
| **Configs only** | `fish scripts/restore.fish --configs` |
| **Themes only** | `fish scripts/restore.fish --themes` |
| **Bluetooth Mic Fix** | `fish scripts/bluetooth-mic-fix.fish` |
| **Maintenance** | `fish scripts/maintenance.fish [--all \| --update \| --clean-cache \| --orphans \| --journal \| --snapshots \| --flatpak]` |
| **Install Opencode + OAC** | `fish scripts/install-opencode.fish` |
| **Theme Info** | `fish scripts/theme-info.fish` |
| **Install Auto Backup Timer** | `cp systemd/* ~/.config/systemd/user/ && systemctl --user daemon-reload && systemctl --user enable --now dotfiles-backup.timer` |

## What each script does

### `backup.fish`

Snapshots your current system state into the repo:

1. **Packages** — exports native (`pacman -Qqen`) and AUR (`pacman -Qqem`) lists
2. **Fish config** — copies `~/.config/fish/`, strips `fish_variables` and `fish_history`
3. **KDE configs** — selective Plasma 6 safe files (`kdeglobals`, `kwinrc`, `plasmarc`, `kcminputrc`, `kwinrulesrc`, etc.)
4. **Terminal configs** — Alacritty, Kitty, Ghostty (atomic copy — temp file, then rename)
5. **Fastfetch** — copies `~/.config/fastfetch/`
6. **Custom theme export** — reads `style.env` from KDE, copies only active theme assets from `~/.local/share/` (color scheme, plasma theme, window decoration, icons, cursors, splash) into `config/themes/`, then compresses into `themes.tar.gz`
7. **Theme package deps** — detects which pacman/paru packages own your active theme files (`/usr/share/icons/*`, color schemes, etc.) and writes them to `packages/theme-deps.txt`
8. **KDE style vars** — exports semantic theme values (icon theme, cursor, color scheme, font) to `config/kde/style.env` via `kde_style.fish`
9. **Sanity check** — verifies critical files were written

### `audit.fish`

Comprehensive pre-restore validation across **7 domains** (37 checks):

- **Package Lists** — validates every package exists in repos/AUR, checks for duplicates, cross-list overlap, and count drift
- **Config Validation** — syntax-checks Fish, TOML (Alacritty), KDE INI files, `style.env`, and Fastfetch JSONC
- **Backup Coverage** — cross-references backup scope against system `~/.config/`, reports gaps
- **Dependency Consistency** — scans `config.fish` for referenced commands, cross-references against package lists; validates fonts, color scheme files, and KDE restore tools
- **Drift Detection** — compares timestamps of backed-up files vs system originals, reports staleness in days
- **Security Scan** — scans all tracked configs for keys, tokens, private keys
- **Script Health** — syntax-checks all scripts, verifies backup/restore file list sync

Run with `--packages`, `--configs`, `--coverage`, `--deps`, `--drift`, `--secrets`, `--scripts`, or `--all` (default).

Exit code: `0` = safe to restore (warnings allowed), `1` = blocking errors.

### `restore.fish`

Restores from the repo with three modes:

| Mode | What it does |
|------|-------------|
| `--all` (default) | Installs packages → restores configs → restores themes + applies style |
| `--configs` | Fish, KDE configs, Alacritty/Kitty/Ghostty, Fastfetch (no sudo needed) |
| `--themes` | Extracts `themes.tar.gz` → `~/.local/share/` + applies `style.env` via `kwriteconfig6/5` |

Package install includes:
- Native packages from `pacman-native.txt` via `sudo pacman -S`
- AUR packages from `pacman-foreign.txt` via `paru -S`
- Theme packages from `theme-deps.txt` (auto-detected at backup time) — split into native/AUR with `pacman -Si` check

Supports both Plasma 6 (`kwriteconfig6`, `kbuildsycoca6`) and Plasma 5 fallbacks.

### `bluetooth-mic-fix.fish`

Fixes PipeWire Bluetooth audio when the built-in mic interferes with headset output:

1. Prevents PipeWire from auto-switching to HSP/HFP headset profile (mic takeover)
2. Forces high-quality A2DP codecs (SBC, SBC-XQ, AAC)
3. Sets built-in mic volume to a user-defined level (default 35%)
4. Restarts PipeWire/WirePlumber services

Use this when your Bluetooth earbuds sound muffled or drop to headset mode after a call.

### `maintenance.fish`

System upkeep for Arch/CachyOS with interactive or CLI mode:

- **System update** — official repos (`pacman -Syu`) and AUR (`paru -Syu --aur`)
- **Package cache cleanup** — removes uninstalled caches, keeps last 2 versions
- **Orphan removal** — finds and removes unused dependencies with confirmation
- **Journal log cleanup** — prunes systemd journals by age
- **Snapper snapshot management** — cleans old BTRFS snapshots per config
- **Flatpak maintenance** — updates Flatpaks and removes unused runtimes

Flags: `--all`, `--update`, `--clean-cache`, `--orphans`, `--journal`, `--snapshots`, `--flatpak`

### `install-opencode.fish`

Installs **opencode CLI** (via `paru -S opencode` or official script), then optionally installs **OpenAgentsControl (OAC)** globally.

### `theme-info.fish`

Displays current KDE theme settings:
- Plasma Style, Color Scheme, Window Decorations
- Icon Theme, Cursor Theme (reads from both Plasma 6 `kcminputrc` and Plasma 5 `kdeglobals`)
- Application Style
- Fonts (General, Fixed Width, Menu — shown as "Family, Size")
- GTK Theme, Icons, Font
- Splash Screen engine and theme

Supports both `kreadconfig6` and `kreadconfig5` with auto-fallback.

### `kde_style.fish`

Exports active KDE theme values to `config/kde/style.env`:
- Icon theme, cursor theme (Plasma 6 `kcminputrc` with Plasma 5 `kdeglobals` fallback), color scheme, font

Used by `backup.fish` to capture theme settings semantically (not raw config files).

## Auto backup timer

Two systemd user units in `systemd/` that run `backup.fish` → commit → push daily:

```
dotfiles-backup.timer     → fires at midnight (or on next boot if PC was off)
dotfiles-backup.service   → backup → git add → git commit → git push
```

If nothing changed, it skips the commit and push — no empty commits, no spam.

**Install via menu:** `Extras → 3) Install Auto Backup Timer`

## Restoring on a fresh install

```sh
git clone git@github.com:anas1412/dotfiles.git ~/dotfiles
cd ~/dotfiles
fish scripts/restore.fish --all     # packages + configs + themes
```

> [!NOTE]
> On a completely fresh system, ensure `fish`, `git`, `sudo`, `paru` are installed first. The rest is handled by the restore script.
>
> You can also restore selectively:
> ```sh
> fish scripts/restore.fish --configs   # skip packages and themes
> fish scripts/restore.fish --themes    # just custom themes + style
> ```

## Fastfetch config

Custom fastfetch config at [`config/fastfetch/config.jsonc`](config/fastfetch/config.jsonc). Uses the `arch_small` logo and displays OS, kernel, uptime, packages, shell, WM, terminal, CPU/GPU temps, and memory. Automatically backed up by `backup.fish`.
