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

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  time.hardwareClockInLocalTime = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
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
      sessionCommands = "";
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
	xorg.xbacklight
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

  config = ''
    Section "Screen"
        Identifier     "Screen0"
        Device         "Device0"
        Monitor        "Monitor0"
        DefaultDepth   24
        Option         "Stereo" "0"
        Option         "nvidiaXineramaInfoOrder" "DFP-5"
        Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
        Option         "SLI" "Off"
        Option         "MultiGPU" "Off"
        Option         "BaseMosaic" "off"
        SubSection     "Display"
        Depth          24
        EndSubSection
    EndSection
  '';
  };

  # allow manual for dev purpose
  documentation.dev.enable = true;
  documentation.enable = true;
  documentation.man.enable = true;
  
  # allow nixos to install achats-in-app apps
  nixpkgs.config.allowUnfree = true;

  services.picom.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "caps:escape";

  # enable NVIDIA drivers
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
  hardware.nvidia.prime = {
	   offload = {
		  enable = true;
		  enableOffloadCmd = true;
       };
	  # Make sure to use the correct Bus ID values for your system!
	  intelBusId = "PCI:0:2:0";
	  nvidiaBusId = "PCI:1:0:0";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # screen brightness
  # programs.light.enable = true;
  # services.actkbd = {
    # enable = true;
    # bindings = [
      # { keys = [ 232 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/brightnessctl -s +5%"; }
      # { keys = [ 233 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/brightnessctl -s 5%-"; }
    # ];
  # };
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
  # '';

  # enable bluetooth
  services.blueman.enable = true;

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

  security.sudo.wheelNeedsPassword = false;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerdfonts
    ];
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

  # All values except 'enable' are optional.
 #services.redshift = {
 #  enable = true;
 #  brightness = {
 #    # Note the string values below.
 #    day = "1";
 #    night = "1";
 #  };
 #  temperature = {
 #    day = 5500;
 #    night = 3700;
 #  };
 #};
  #services.geoclue2.appConfig.redshift.isAllowed = true;

  # steam
  programs.steam.enable = true;

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

    # useful for dev
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
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    docker
    nvidia-podman
    direnv
    xsel
    # tldr

    # useful
    spotify
    keepassxc
    # ifwifi
    file
    feh
    pavucontrol
    flameshot
    sshfs
    krb5
    wget
    brightnessctl
    # actkbd
    redshift
    geoclue2 # used by redshift
    playerctl

    # games
    prismlauncher
    config.boot.kernelPackages.nvidiaPackages.stable
    # lshw
    steam
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
