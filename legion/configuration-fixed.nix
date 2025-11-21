# Configuration NixOS Corrigée - Lenovo Legion Pro 5 16 (Ryzen 9 9955HX + RTX 5070)
# Version avec correction LUKS/Swap

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # VPN
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  nixpkgs.config.allowUnfree = true;

  home-manager.users.evariste = { pkgs, lib, ... }: let
    continue = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        name = "continue";
        publisher = "Continue";
        version = "1.1.40";
        sha256 = "sha256-P4rhoj4Juag7cfB9Ca8eRmHRA10Rb4f7y5bNGgVZt+E=";
        arch = "linux-x64";
      };
      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.stdenv.cc.cc.lib];
    };
  in {
    home.stateVersion = "25.05";

    nixpkgs.config = {
      allowUnfree = true;
    };

    home.activation.setupNvimDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.local/state/nvim/undo"
      mkdir -p "$HOME/.local/state/nvim/swap"
      mkdir -p "$HOME/.local/state/nvim/backup"
      '';

    services.mako = {
      enable = true;
      settings = {
        default-timeout = 5000;
        max-history = 10;
        anchor = "top-right";
        width = 300;
        height = 100;
        margin = "10,10,10,10";
        padding = "10,15,10,15";
        border-size = 2;
        border-color = "#89b4fa";
        background-color = "#1e1e2e";
        text-color = "#cdd6f4";
      };
    };

    xdg.configFile."mako/config".text = ''
      [mode=do-not-disturb]
      invisible=1

      [mode=default]
      invisible=0
    '';

    programs.neovim = {
      enable = true;
      extraPackages = with pkgs; [
        lua-language-server
        stylua
        ripgrep
        tree-sitter
      ];

      plugins = with pkgs.vimPlugins; [
        lazy-nvim
      ];

      extraLuaConfig =
        ''
        vim.o.tabstop = 4
        vim.o.shiftwidth = 4
        vim.o.softtabstop = 4
        vim.o.expandtab = true
        vim.o.colorcolumn = "80"
        vim.o.textwidth = 80

        require("lazy").setup({
            defaults = { lazy = true },
            spec = {
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
            },
            })

      require("lspconfig").clangd.setup({ cmd = { "/run/current-system/sw/bin/clangd" } })
        '';
    };

    xdg.configFile."nvim/parser".source =
      let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
              c
              lua
        ])).dependencies;
      };
    in
      "${parsers}/parser";

    xdg.configFile."nvim/lua".source = ./lua;

    home.packages = [
      continue
    ];

    programs.vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [
      ] ++ [
        continue
      ];
    };
  };

  # Define on which hard drive you want to install Grub.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  # boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "deadbeef";

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      ncurses
    ];
  };

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    extraEntries = ''
      menuentry "Reboot" {
        reboot
      }
      menuentry "Poweroff" {
        halt
      }
      menuentry "UEFI" {
        fwsetup
      }
    '';
    extraConfig = "
      GRUB_DEFAULT=saved
      GRUB_SAVEDEFAULT=true
      ";
    theme = pkgs.stdenv.mkDerivation rec {
      pname = "catppuccin-grub";
      version = "1";
      src = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "grub";
        rev = "803c5df";
        hash = "sha256-/bSolCta8GCZ4lP0u5NVqYQ9Y3ZooYCNdTwORNvR7M0=";
      };
      installPhase = "
        mkdir -p $out
        cp -r src/catppuccin-mocha-grub-theme/* $out/
      ";
      meta = {
        description = "catppuccin-grub";
      };
    };
  };

  # ============================================
  # LUKS Configuration - FIXED VERSION
  # ============================================
  
  # Reuse passphrase between root and swap devices
  boot.initrd.luks.reusePassphrases = true;

  boot.initrd.luks.devices = {
    nixroot = {
      device = "/dev/disk/by-uuid/dab7471b-9cf5-415c-b48d-dc47c5cd3b0e";
      preLVM = true;  # Keep true for LVM root
    };
    cryptswap = {
      device = "/dev/disk/by-uuid/369601d7-c62e-4c57-839b-15c0c9e87196";
      preLVM = false; # Changed from true to false - swap ne nécessite pas LVM
    };
  };

  swapDevices = [
    { device = "/dev/mapper/cryptswap"; }
  ];

  # ============================================

  # Power management
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = false;

  services.tlp = {
    enable = false;
    settings = {
      # Gouverneurs
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Politique énergétique : priorité performance sur secteur
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Supprime les limites sur fréquence CPU sur secteur
      CPU_SCALING_MIN_FREQ_ON_AC = 1000000;
      CPU_SCALING_MAX_FREQ_ON_AC = 0;

      # Si jamais nécessaire (pour forcer désactivation du throttling léger)
      CPU_BOOST_ON_AC = 1;
    };
  };

  boot.initrd.availableKernelModules = [
    "thinkpad_acpi"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "amdgpu"
  ];

  # Fingerprint
  services.fprintd = {
    enable = true;
  };

  # Hyperland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # Required services for Wayland/Hyperland
  services.dbus.enable = true;

  # Desktop environment essentials
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Fix for screen sharing, portals, and authentication
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Polkit authentication for GUI apps
  security.polkit.enable = true;

  # Disable X11 and i3 since we're using Wayland
  services.xserver.enable = false;
  services.picom.enable = false;

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # VirtualBox support
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "evariste" ];

  virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.addNetworkInterface = false;

  networking.hostName = "evariste";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.macAddress = "permanent";
  networking.networkmanager.ethernet.macAddress = "permanent";
  networking.networkmanager.wifi.scanRandMacAddress = false;
  systemd.services.wpa_supplicant.environment.OPENSSL_CONF = pkgs.writeText "openssl.conf" ''
    openssl_conf = openssl_init
    [openssl_init]
    ssl_conf = ssl_sect
    system_default = system_default_sect
    [system_default_sect]
    Options = UnsafeLegacyRenegotiation
    [system_default_sect]
    CipherString = Default:@SECLEVEL=0
  '';

  # libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd];
      };
    };
  };

  programs.virt-manager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # allow manual for dev purpose
  documentation.dev.enable = true;
  documentation.enable = true;
  documentation.man.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "fr";
  services.xserver.xkb.options = "caps:escape";

  # enable bluetooth
  services.blueman.enable = true;

  # Bluetooth audio
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    audio.enable = true;
    wireplumber.enable = true;

    wireplumber.extraConfig = {
      "policy.default" = {
        "media.follow-default" = true;
      };
    };
  };

  # Define a user account.
  users.users.evariste = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" "dialout" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      firefox-wayland
      discord
      tree
    ];
  };

  # docker settings
  virtualisation.docker.enable = true;

  security.sudo.wheelNeedsPassword = false;

  fonts.packages = with pkgs; [
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "python" "man" ];
        theme = "awesomepanda";
      };
    };
  };

  # direnv
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # steam
  programs.steam.enable = true;

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "20";
    HYPRCURSOR_SIZE = "20";

    # VA-API + Firefox Wayland
    LIBVA_DRIVER_NAME = "iHD";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    MOZ_ENABLE_WAYLAND = "1";
    WLR_RENDERER = "gl";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL = "1";
  };

  # AMD GPU (integrated) + NVIDIA GPU (discrete) setup
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  # AMD Graphics (integrated GPU - Radeon 610M)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
    ];
  };

  hardware.amdgpu = {
    opencl.enable = true;
    amdvlk.enable = true;
  };

  # NVIDIA GPU (discrete - RTX 5070) configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME offload configuration
    # Note: For your system, you need to find the correct PCI bus IDs
    # Run: nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D'"
    # Then convert the output (e.g., "00:02.0" becomes "PCI:0:2:0")
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # IMPORTANT: Replace these with your actual PCI bus IDs
      # AMD integrated GPU (Radeon 610M) - usually on bus 0
      amdgpuBusId = "PCI:8:0:0";
      # NVIDIA discrete GPU (RTX 5070) - usually on bus 1
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Kernel parameters for NVIDIA Wayland support
  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # hyprland
    waybar
    rofi-wayland
    mako
    hyprlock
    grim
    slurp
    wl-clipboard
    libnotify
    hyprshot
    hyprpicker
    pywal
    blueman
    bluez
    networkmanager
    swww
    fd
    wofi
    swaybg
    hypridle
    hyprcursor
    bibata-cursors
    powertop
    fastfetch

    # useful for dev
    nodejs
    cargo
    bat
    man-pages
    man-pages-posix
    clang
    gcc
    zip
    unzip
    gnumake
    python311
    gdb
    valgrind
    clang-tools
    git
    zsh
    alacritty
    kitty
    oh-my-zsh
    vim
    docker
    direnv
    xsel
    nixpkgs-lint

    # useful
    spotify
    keepassxc
    killall
    slack
    file
    feh
    pavucontrol
    pulseaudio
    flameshot
    sshfs
    krb5
    wget
    brightnessctl
    actkbd
    redshift
    geoclue2
    playerctl
    vlc
    arduino
    nautilus
    s-tui
    htop
    gdu
    ncdu
    libva
    libva-utils
    mesa
    vaapiIntel
    vaapiVdpau
    vaapi-intel-hybrid
    libreoffice
    fprintd
    tldr
    chromium
    linuxHeaders
    gemini-cli
    parsec-bin
    pciutils

    # games
    prismlauncher
    steam
    moonlight-qt
    ffmpeg
    nvtopPackages.nvidia
  ];

  # Copy the NixOS configuration file
  system.copySystemConfiguration = true;

  system.stateVersion = "25.05";
}
