# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

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

                                                boot.initrd.luks.devices = {
                                                nixroot = {
                                                device = "/dev/disk/by-uuid/56053471-6300-4bb3-81fa-643f7b8eeee4";
                                                preLVM = true;
                                                };
                                                cryptswap = {
                                                device = "/dev/disk/by-uuid/22139a66-1ffa-44c9-af17-7cc8b4b2aa75";
                                                preLVM = true;
                                                };
                                                };

                                                swapDevices = [
                                                { device = "/dev/mapper/cryptswap"; }
                                                ];

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
# trimmed irrelevant ones
"thinkpad_acpi"
"nvidia"
"nvidia_modeset"
"nvidia_uvm"
"nvidia_drm"
];
# Power management

# fingerprint
services.fprintd = {
enable = true;
};
# !fingerprint

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
# services.displayManager.defaultSession = "hyprland";
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
# Hyperland

services.gvfs.enable = true;
services.udisks2.enable = true;

boot.kernelPackages = pkgs.linuxPackages_latest;

# VirtualBox support
virtualisation.virtualbox.host.enable = true;
users.extraGroups.vboxusers.members = [ "evariste" ];

virtualisation.virtualbox.host.enableKvm = true;
virtualisation.virtualbox.host.addNetworkInterface = false;

networking.hostName = "evariste"; # Define your hostname.
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
# libvirt

# Set your time zone.
time.timeZone = "Europe/Paris";
time.hardwareClockInLocalTime = true;

# Select internationalisation properties.
i18n.defaultLocale = "en_US.UTF-8";
console = {
  font = "Lat2-Terminus16";
  useXkbConfig = true; # use xkbOptions in tty.
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

# Ceci active un policy script personnalisé pour suivre la sortie par défaut
  wireplumber.extraConfig = {
    "policy.default" = {
      "media.follow-default" = true;
    };
  };
};

# Define a user account. Don't forget to set a password with ‘passwd’.
users.users.evariste = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" "dialout" ]; # Enable ‘sudo’ for the user.
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
# autres polices si tu veux
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
  HYPRCURSOR_SIZE="20";

# VA-API + Firefox Wayland
  LIBVA_DRIVER_NAME = "iHD";
  LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
  MOZ_ENABLE_WAYLAND = "1";
  WLR_RENDERER = "gl"; # ou "gl" si Vulkan rame
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  NIXOS_OZONE_WL = "1";
};

services.xserver.videoDrivers = [ "intel" "modesetting" "nvidia" ];

hardware.nvidia = {
  modesetting.enable = true;                         # Nécessaire pour offload
    powerManagement.enable = true;                     # Active la gestion d’énergie
    powerManagement.finegrained = true;                # Éteint le GPU quand inutilisé
    open = false;                                      # Utilise le pilote propriétaire (stable)
    nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;

  prime = {
    offload = {
      enable = true;                                 # Active le mode offload
        enableOffloadCmd = true;                       # Crée le script nvidia-offload
    };

    intelBusId = "PCI:0:2:0";                        # Bus de ton iGPU Intel
      nvidiaBusId = "PCI:1:0:0";                       # Bus de la Quadro T500
  };
};

# OpenGL
hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [ 
    intel-media-driver
    vpl-gpu-rt
  ];
};

# List packages installed in system profile. To search, run:
environment.systemPackages = with pkgs; [
# hyprland
  waybar
  rofi-wayland
  mako  # Notification daemon for Wayland
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
# rpi-imager

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
  geoclue2 # used by redshift
  playerctl
  vlc
  arduino
  nautilus
  s-tui
  htop
  gdu
  ncdu
  intel-media-driver  # important pour Iris Xe
  libva
  libva-utils
  mesa
  vaapiIntel
  vaapiVdpau
  mesa
  vaapi-intel-hybrid
  libreoffice
  fprintd
  tldr
  chromium
  linuxHeaders
  gemini-cli
  parsec-bin

# games
  prismlauncher
  steam
  moonlight-qt
  ffmpeg
  nvtopPackages.nvidia
  ];

# Copy the NixOS configuration file and link it from the resulting system
# (/run/current-system/configuration.nix). This is useful in case you
# accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

# This value determines the NixOS release from which the default
# settings for stateful data, like file locations and database versions
# on your system were taken. It's perfectly fine and recommended to leave
# this value at the release version of the first install of this system.
# Before changing this value read the documentation for this option
# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
  }
