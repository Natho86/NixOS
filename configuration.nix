# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./vim.nix
      #./wireguard.nix
      #./rtl88xx.nix
    ];

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 8;

  networking.hostName = "redpill-nix-yoga"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking = {
    networkmanager.enable = true;
    #useDHCP = true;
    #interfaces.enp0s20f0u2 = {
    #  ipv4.addresses = [{
    #    address = "192.168.50.120";
    #    prefixLength = 24;
    #  }];
   # };
    #defaultGateway = {
    #  address = "192.168.50.1";
    #  interface = "enp0s20f0u2";
    #};
    #nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  # Swap file
  swapDevices = [
    { 
      device = "/swapfile";
      size = 32 * 1024; # size of RAM to allow hybrid sleep.
    }
  ];

  boot.kernel.sysctl = { "vm.swappiness" = 0; };

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # Optimize storage
  # You can also manually optimize the store via:
  #    nix-store --optimise
  # Refer to the following link for more details:
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;


	# WINDOW MANAGER STUFF
  
  # KDE Plasma
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm.wayland.enable = true;


	# OLD CONFIG - GNOME -----------------------------------
  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  # -------------------------------------------------------
  
	# HYPRLAND ---------------------------------------------
	# Greeter
  #services.greetd = {
  #	enable = true;
##		settings = {
  #		default_session.command = ''
#				${pkgs.greetd.tuigreet}/bin/tuigreet \
#					--time \
#					--asterisks \
#					--cmd Hyprland
#					--remember
#				'';
#			};
#	};


  #programs.hyprland = {
#		enable = true;
#		xwayland.enable = true;	# For X applications
#	};

#	environment.sessionVariables = {
#		# If your cursor becomes invisible
#		# WLR_NO_HARDWARE_CURSORS = "1";
#		# Hint Electron apps to use Wayland
#		NIXOS_OZONE_WL = "1";
#	};

  #xdg.portal.enable = true;
  #xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];


	# --------------------------------------------HYPRLAND 

	# Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

	fonts.packages = with pkgs; [
		(nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Meslo" "Hack" "Terminus" ]; })
	];


  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nath = {
    isNormalUser = true;
    description = "Nath";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
  ];
  };

  #programs.hyprlock.enable = true;
  #services.hypridle.enable = true;

  # Install browsers
  programs.firefox.enable = true;
	#programs.chromium.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

	# AppImage
	programs.appimage.binfmt = true;
	programs.appimage.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

  #burpsuite

	# hyprland
	#rofi	# hyprland app launcher		moved to home.nix
  #dunst
  #hypridle
  #hyprlock
  #hyprutils
  #hyprpaper
  #kitty	# Hyprland default terminal
	libnotify
	networkmanagerapplet
  nmap
  #swww
  #waybar	
  # override for Hyperland
  #(pkgs.waybar.overrideAttrs (oldAttrs: {
#		mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
  #	})
  #)

  # browsers
  brave
  chromium	# for some reason, doesn't persist when using programs.chromium.enable

	# development
	code-cursor
	git
	vim

	# utilities
	bat
  brightnessctl
	btop
	curl
	dnsutils	# dig and nslookup
	file
	ffmpeg
	gnupg
	iotop
	iperf3
	jq
	ldns		# alternative to dig, provides command "drill"
	lm_sensors
  mtr		# network diagnostic
  pavucontrol
	p7zip
	pciutils	# lspci	
  ranger
  ripgrep
	sysstat
  tree
  ueberzug # for ranger image preview
	unzip
  usbutils	# lsusb
  vlc
	wget
  which
  wireguard-tools
	wpscan 		# api key Ny9htvNitGRTrXmI0qxNgrGsn8pebf6QLicnBUP6tp0
	xz
	zip
	
	# other
  	appimage-run
	whatsapp-for-linux
  ];

  environment.variables.EDITOR = "vim";

	environment.shells = with pkgs; [ zsh ];
	users.defaultUserShell = pkgs.zsh;
	programs.zsh.enable = true;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  #services.grafana = {
  #enable = true;
  #settings = {
  #  server = {
  #    # Listening Address
  #    http_addr = "127.0.0.1";
  #    # and Port
  #    http_port = 3000;
  #    # Grafana needs to know on which domain and URL it's running
  #    #domain = "localhost";
  #    root_url = "https://localhost/grafana/"; # Not needed if it is `https://your.domain/`
  #    serve_from_sub_path = true;
  #  };
  #};
#};

  #services.prometheus = {
  #  enable = true;
  #  port = 9090;
  #};

  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

	hardware.graphics = {
		enable = true;
		extraPackages = with pkgs; [
			intel-ocl
			vpl-gpu-rt
      intel-compute-runtime
		];
	};


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
