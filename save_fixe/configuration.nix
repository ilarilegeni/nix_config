# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "evariste"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  time.hardwareClockInLocalTime = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
      sessionCommands = ''
        xrandr --output DP-0 --auto --primary --right-of HDMI-0 --output DP-2 --auto --right-of DP-0
      ''; 
    # xrandr --output DP-0 --auto --primary --right-of HDMI-0 --output HDMI-0 --auto
    # xrandr --output DP-0 --auto --primary --output DP-2 --auto --left-of DP-0
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
		dmenu
		i3status
		i3lock
		i3lock-color
		xorg.xdpyinfo
		dunst
		betterlockscreen
		i3blocks
      ];
    };
  };

  # allow manual for dev purpose
  documentation.dev.enable = true;
  documentation.enable = true;
  documentation.man.enable = true;
  
  # allow nixos to install achats-in-app apps
  nixpkgs.config.allowUnfree = true;

  services.picom.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout  = "us";
    xkbVariant = "intl";
    xkbOptions = "caps:escape";
  };

  # keybinds
  # sound.mediaKeys.enable = true;
  # services.actkbd = {
    # enable = true;
    # bindings = [
      # { keys = [ 164 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl play-pause"; }
      # { keys = [ 165 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/playerctl previous"; }
      # { keys = [ 163 ]; events = [ "key" ]; command = "playerctl next"; }
      # { keys = [ 114 ]; events = [ "key" ]; command = "playerctl volume -0.1"; }
      # { keys = [ 115 ]; events = [ "key" ]; command = "playerctl volume +0.1"; }
    # ];
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # enable bluetooth
  services.blueman.enable = true;

  # Enable sound.
  sound.enable = true;
    hardware = {
        pulseaudio = {
                enable = true;
                # Enable extra bluetooth codecs
                package = pkgs.pulseaudioFull;
                # Automatically switch audio to connected bluetooth device when it connects
                extraConfig = "
                        load-module module-switch-on-connect
                ";
        };
        bluetooth = {
                # Enable support for bluetooth
                enable = true;
                # Powers up the default bluetooth controller on boot
                powerOnBoot = true;
                # Modern headsets will generally try to connect using the A2DP profile, enables it
                settings.General.Enable = "Source,Sink,Media,Socket";
        };
    };
  nixpkgs.config.pulseaudio = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.evariste = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    packages = with pkgs; [
      firefox
      discord
      tree
    ];
  };

  # docker settings
  virtualisation.docker.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerdfonts
    ];
  };

  # test
  services.xserver.libinput.mouse.accelSpeed = null;

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


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # stylish
    rofi
    picom
    nerdfonts
    polybar
    nitrogen
    libmpdclient

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
    nvidia-podman
    direnv
    xsel
    maven

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

    # games
    prismlauncher
    steam
    protonup-qt
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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
