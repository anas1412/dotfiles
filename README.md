# dotfiles

Managed configs for my CachyOS (Arch Linux) KDE Plasma desktop.

```
       /\        blackbox@blackbox
      /  \       -----------------
     /    \      OS         ➜  CachyOS x86_64
    /      \     Base       ➜  Arch Linux
   /   ,,   \    Kernel     ➜  Linux 7.0.5-2-cachyos
  /   |  |   \   Uptime     ➜  21 hours, 10 mins
 /_-''    ''-_\  Packages   ➜  1425 (pacman)
                 Shell      ➜  fish 4.7.1
                 WM         ➜  KWin (Wayland)
                 Terminal   ➜  konsole 26.4.1
                 CPU        ➜  Intel(R) Core(TM) i5-10300H (8) @ 4.50 GHz - 77.0°C
                 GPU 1      ➜  NVIDIA GeForce GTX 1650 - 54.0°C [Discrete]
                 GPU 2      ➜  Intel UHD Graphics @ 1.05 GHz [Integrated]
                 Memory     ➜  8.42 GiB / 15.39 GiB (55%)
```

## Structure

```
dotfiles/
├── install.fish              # Main entry point (menu-driven)
├── scripts/
│   ├── audit.fish            # Pre-restore health check
│   ├── backup.fish           # Snapshot current configs
│   ├── restore.fish          # Restore configs + packages
│   ├── kde_style.fish        # Export KDE theme vars
│   └── bluetooth-mic-fix.fish # Fix BT audio + built-in mic conflict
├── config/
│   ├── fish/                 # Fish shell (pure prompt, bun integration, mt5)
│   ├── alacritty/            # Alacritty terminal
│   ├── kitty/                # Kitty terminal (empty — placeholder)
│   ├── ghostty/              # Ghostty terminal (empty — placeholder)
│   ├── fastfetch/            # Fastfetch system info config
│   ├── git/                  # Git config placeholder
│   └── kde/                  # KDE Plasma config snapshots
│       ├── kdeglobals
│       ├── kwinrc
│       ├── plasmarc
│       ├── dolphinrc
│       ├── konsolerc
│       ├── kglobalshortcutsrc
│       ├── mimeapps.list
│       └── style.env         # KDE theme vars (icon, cursor, color, font)
└── packages/
    ├── pacman.txt            # Full native package list
    ├── pacman-native.txt     # Native packages (backup)
    ├── pacman-foreign.txt    # AUR packages (via paru)
    └── flatpak.txt           # Flatpak (empty — placeholder)
```

## Requirements

- **Arch Linux** (CachyOS recommended)
- **Fish shell** (required for the scripts)
- **sudo** (for package installs during restore)
- **paru** (for AUR package restore)

## Quick start

Clone and run the installer:

```sh
git clone git@github.com:anas1412/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.fish
```

## Usage

### Menu-driven (recommended)

```sh
./install.fish
```

```
DOTFILES MANAGER - ANAS1412
==================================
1) Backup
2) Restore
3) Audit
4) Bluetooth Mic Fix
5) Exit
==================================
```

### Manual commands

| Action | Command |
|--------|---------|
| **Backup** | `fish scripts/backup.fish` |
| **Audit** | `fish scripts/audit.fish` |
| **Restore** | `fish scripts/restore.fish` |
| **Bluetooth Mic Fix** | `fish scripts/bluetooth-mic-fix.fish` |

## What each script does

### `backup.fish`
1. Cleans old snapshots from `config/`
2. Exports native packages to `packages/pacman-native.txt`
3. Exports AUR packages to `packages/pacman-foreign.txt`
4. Copies Fish config from `~/.config/fish`
5. Copies KDE config files (selective safe files)
6. Copies terminal configs (Alacritty, Kitty, Ghostty)
7. Exports KDE theme vars (icons, cursors, color scheme, font) via `kde_style.fish`

### `audit.fish`
Checks system prerequisites and file integrity:
- Required commands (`pacman`, `fish`, `git`, `kwriteconfig5`)
- Directory structure (`scripts/`, `config/`, `packages/`)
- Required files (`pacman.txt`, backup/restore/kde_style scripts, `style.env`)
- KDE runtime config (`kdeglobals`, `kwinrc`, `plasmarc`)

Returns exit code 0 when safe to restore, 1 on warnings.

### `restore.fish`
1. Installs native packages from `pacman-native.txt` via `sudo pacman -S`
2. Installs AUR packages from `pacman-foreign.txt` via `paru -S`
3. Restores Fish config
4. Restores KDE config files
5. Restores terminal configs (Alacritty, Kitty, Ghostty)
6. Applies KDE theme from `style.env` using `kwriteconfig5`

### `bluetooth-mic-fix.fish`
Fixes PipeWire Bluetooth audio when the built-in mic interferes with headset output:
1. Prevents PipeWire from auto-switching to HSP/HFP headset profile (mic takeover)
2. Forces high-quality A2DP codecs (SBC, SBC-XQ, AAC)
3. Sets built-in mic volume to a user-defined level (default 35%)
4. Restarts PipeWire/WirePlumber services

Use this when your Bluetooth earbuds sound muffled or drop to headset mode after a call.

## Restoring on a fresh install

```sh
git clone git@github.com:anas1412/dotfiles.git ~/dotfiles
cd ~/dotfiles
fish scripts/restore.fish
```

> [!NOTE]
> On a completely fresh system, ensure `fish`, `git`, `sudo`, `paru` are installed first. The rest is handled by the restore script.

## Fastfetch config

The custom fastfetch config is at [`config/fastfetch/config.jsonc`](config/fastfetch/config.jsonc). It uses the `arch_small` logo and displays OS, kernel, uptime, packages, shell, WM, terminal, CPU/GPU temps, and memory.
