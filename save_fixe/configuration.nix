# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.efiSysMountPoint = "/boot";

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

  networking.hostName = "evariste";
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  time.hardwareClockInLocalTime = true;

  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

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

  # Load amd driver for Xorg and Wayland
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "amd_iommu=pt" "ivrs_ioapic[32]=00:14:00" "iommu=soft" ];
  services.xserver.videoDrivers = ["amdgpu"];
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true;
  };

  # allow manual for dev purpose
  documentation.dev.enable = true;
  documentation.enable = true;
  documentation.man.enable = true;
  
  # allow nixos to install achats-in-app apps
  nixpkgs.config.allowUnfree = true;

  # services.picom.enable = true;

  # keybinds
  services.actkbd = {
    enable = true;
    bindings = [
      # Volume down key (code 114)
      { keys = [ 114 ]; events = [ "key" ]; command = "amixer set Master 5%-"; }
      # Volume up key (code 115)
      { keys = [ 115 ]; events = [ "key" ]; command = "amixer set Master 5%+"; }
    ];
  };

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

  services.pulseaudio = {
                enable = false;
                package = pkgs.pulseaudioFull;
                extraConfig = "
                        load-module module-switch-on-connect
                ";
        };
  nixpkgs.config.pulseaudio = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.evariste = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    packages = with pkgs; [
      firefox
      discord
      tree
    ];
  };

  # docker settings
  virtualisation.docker.enable = true;

  fonts.packages = with pkgs; [
    # autres polices si tu veux
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  # steam setup
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  programs = {
    zsh = {
        enable = true;
        enableCompletion = true;
        ohMyZsh = {
        enable = true;
        plugins = [ "git" "python" "man" ];
        theme = "avit";
        };
    };
  };

  # enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];  

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    kitty

    # stylish
    rofi
    picom
    nitrogen

    # dev
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
    oh-my-zsh
    vim
    docker
    direnv
    xsel
    maven
    nodejs

    # useful
    slack
    spotify
    keepassxc
    file
    feh
    pavucontrol
    flameshot
    sshfs
    krb5
    wget
    playerctl
    docker
    actkbd
    virt-manager
    sbctl
    nautilus
    s-tui # for temps
    htop
    gdu
    ncdu

    # games
    prismlauncher
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
  system.stateVersion = "23.05"; # Did you read the comment?

}
