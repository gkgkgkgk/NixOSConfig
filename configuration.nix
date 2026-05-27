# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NTFS read/write support (for the Windows partition on nvme0n1p3 etc.)
  # Pulls in ntfs-3g so udisks2/Nemo can mount NTFS volumes.
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.wifi.powersave = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Autologin via greetd. No greeter UI shown — Hyprland starts directly as
  # gavri, and the noctalia-lock.service in home.nix immediately fires the GavBar
  # lockscreen. That lockscreen (unlocked with the normal system password) is the
  # effective "login screen".
  services.greetd = {
    enable = true;
    settings.default_session = {
      # Launch via Hyprland's own `start-hyprland` session wrapper, NOT the bare
      # `Hyprland` binary. The wrapper sets up the session environment that the
      # systemd user units (GavBar, lock, polkit) need; launching bare Hyprland
      # skipped it, producing the "started without start-hyprland" warning and a
      # boot where the desktop came up with no working Wayland/DBus environment.
      command = "start-hyprland";
      user = "gavri";
    };
  };

  # Hyprland. UWSM is disabled so there is a single session manager:
  # home-manager's systemd integration (wayland.windowManager.hyprland.systemd)
  # imports the environment and starts hyprland-session.target before the
  # graphical-session.target user units run. With UWSM on, its session machinery
  # competed with home-manager's, which is what made startup racy.
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = false;
  programs.dconf.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # gvfs powers Nemo's network drives (SMB/SFTP/etc.) and trash integration
  services.gvfs.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gavri = {
    isNormalUser = true;
    description = "Gavri";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Install firefox.
  programs.firefox.enable = true;
  programs.steam = {
    enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    vscode
    claude-code
    blender
    antigravity
    vesktop
    bitwarden-desktop
    unityhub
    codex
    spotify
    gimp
    hyprshot
    fastfetch
    obs-studio
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.xserver.excludePackages = with pkgs; [ xterm ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      inter
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Inter" ];
    };
  };

  # Unlock the GNOME keyring on login so NetworkManager can read saved WiFi passwords
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # PAM service the GavBar lockscreen authenticates against (NOCTALIA_PAM_SERVICE
  # in home.nix points here). Plain system-password auth via pam_unix — no custom
  # PIN logic. Set the password (use a short numeric one if you want a "PIN"):
  #   passwd
  security.pam.services.noctalia-lock.text = ''
    auth required pam_unix.so nullok
    account required pam_permit.so
    session required pam_permit.so
    password required pam_deny.so
  '';

  hardware.openrazer.enable = true;
  hardware.openrazer.users = ["gavri"];
  hardware.enableAllFirmware = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
