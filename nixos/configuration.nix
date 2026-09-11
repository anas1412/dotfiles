# NixOS config generated from the CachyOS install on this machine.
# HP Pavilion Gaming 15-dk1xxx - i5-10300H, Intel UHD + GTX 1650 Mobile
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ---------- boot ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;  # keep ESP from filling

  # ---------- networking ----------
  networking.hostName = "blackbox";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;          # replaces ufw

  # ---------- locale (yours is split en_US / fr_FR) ----------
  time.timeZone = "Africa/Tunis";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_NUMERIC  = "fr_FR.UTF-8";
    LC_TIME     = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_PAPER    = "fr_FR.UTF-8";
    LC_NAME     = "fr_FR.UTF-8";
  };

  # ---------- desktop ----------
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ---------- graphics: Intel iGPU + NVIDIA PRIME offload ----------
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;                        # needed for Steam
    extraPackages = with pkgs; [
      intel-media-driver                       # your intel-media-driver
      vaapiIntel
      vulkan-loader
    ];
  };
  hardware.nvidia = {
    open = true;                               # you run nvidia-open
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;         # gives you `nvidia-offload <app>`
      intelBusId  = "PCI:0:2:0";               # your 00:02.0 UHD
      nvidiaBusId = "PCI:1:0:0";               # your 01:00.0 GTX 1650
    };
  };

  # ---------- audio ----------
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ---------- gaming ----------
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;

  # ---------- services (mapped from your enabled systemd units) ----------
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.printing.enable = true;             # cups
  services.avahi = { enable = true; nssmdns4 = true; };   # was avahi + nss-mdns
  services.thermald.enable = true;             # your 88-98C problem
  services.power-profiles-daemon.enable = true;
  services.switcherooControl.enable = true;    # hybrid GPU switching
  services.openssh.enable = true;
  services.locate.enable = true;               # plocate
  services.fstrim.enable = true;
  virtualisation.docker.enable = true;
  services.flatpak.enable = true;
  services.cron.enable = true;                 # cronie
  hardware.sensor.iio.enable = false;
  programs.dconf.enable = true;

  # ---------- user ----------
  programs.zsh.enable = true;
  users.users.blackbox = {
    isNormalUser = true;
    description = "Black Box";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" "storage" "lp" ];
  };

  # ---------- fonts ----------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono          # your terminal font
    nerd-fonts.meslo-lg
    noto-fonts noto-fonts-cjk-sans noto-fonts-emoji
    liberation_ttf dejavu_fonts cantarell-fonts open-sans
  ];

  # ---------- packages ----------
  nixpkgs.config.allowUnfree = true;           # nvidia, steam, discord
  environment.systemPackages = with pkgs; [
    # browsers
    brave firefox chromium
    # terminals + shell
    kitty alacritty tmux zsh-powerlevel10k fastfetch
    # editors
    vim neovim micro kate ghostwriter
    # dev
    git gh glab lazygit lazydocker go nodejs bun python3 python3Packages.pip pipx
    docker-compose kubectl cmake ninja gcc ripgrep fd jq stow
    # kde apps you had
    dolphin ark okular gwenview spectacle filelight kcalc partition-manager
    kdePackages.kdeconnect-kde kdePackages.kwalletmanager kdePackages.kdialog
    # media
    vlc haruna krita pinta yt-dlp ffmpeg cava mpd rmpc
    # system / monitoring
    btop glances duf mission-center smartmontools lm_sensors pciutils usbutils
    # apps
    discord libreoffice-fresh joplin-desktop qbittorrent localsend meld
    # gaming (beyond programs.steam)
    lutris heroic mangohud protontricks wineWowPackages.stable winetricks
    # misc
    wget curl unzip unrar p7zip rsync speedtest-cli
  ];

  system.stateVersion = "25.05";   # set to the release you install; never change after
}
