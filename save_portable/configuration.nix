# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.permittedInsecurePackages = [
                "qbittorrent-4.6.4"
              ];

  # Define on which hard drive you want to install Grub.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
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
  services.tlp = {
    enable = true;
    settings = {
      # Gouverneurs
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  
      # Politique énergétique : priorité performance sur secteur
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  
      # Supprime les limites sur fréquence CPU sur secteur
      CPU_SCALING_MIN_FREQ_ON_AC = 0;
      CPU_SCALING_MAX_FREQ_ON_AC = 0;
  
      # Si jamais nécessaire (pour forcer désactivation du throttling léger)
      CPU_BOOST_ON_AC = 1;
    };
  };

  boot.initrd.availableKernelModules = [
        # trimmed irrelevant ones
        "thinkpad_acpi"
      ];
  # Power management

  # Hyperland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # Required services for Wayland/Hyperland
  services.dbus.enable = true;
  # security.pam.services.swaylock = { };
  # programs.swaylock.enable = true;
  
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

  # keep clean
  nix.optimise.automatic = true;
  nix.gc.automatic = true;

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
  
  # allow nixos to install achats-in-app apps
  nixpkgs.config.allowUnfree = true;

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
      firefox
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
    WLR_RENDERER = "vulkan"; # ou "gl" si Vulkan rame
  };

  # OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Wayland
    # polkit_kde_agent
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

    # stylish
    rofi
    picom
    # nerdfonts
    polybar
    nitrogen
    libmpdclient

    # useful for dev
    nodejs
    cargo
    bat
    man-pages
    man-pages-posix
    neovim
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
    geoclue2 # used by redshift
    playerctl
    qbittorrent # movies, music, games
    vlc
    arduino
    nautilus
    s-tui # for temps
    htop
    gdu
    ncdu
    intel-media-driver  # important pour Iris Xe
    libva
    libva-utils
    mesa
    vaapiIntel
    vaapiVdpau

    # games
    prismlauncher
    # config.boot.kernelPackages.nvidiaPackages.stable
    steam
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
