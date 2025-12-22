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
  boot.blacklistedKernelModules = [ "option" "usbserial" "rtw89_8852cu" "rtw_8852cu"];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Use the explicit pkgs path instead of 'config.boot' to avoid the null error
  # This forces the specific driver for your 8852CU chip to load
  boot.kernelModules = [ "8852cu" ];
  boot.extraModprobeConfig = ''
    options 8852cu rtw_switch_usb_mode=1
  '';
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.usb-modeswitch.enable = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="35bc", ATTR{idProduct}=="0102", RUN+="${pkgs.kmod}/bin/modprobe rtw89_8852c", RUN+="${pkgs.bash}/bin/sh -c 'echo 35bc 0102 > /sys/bus/usb/drivers/rtw89_8852cu/new_id'"
  '';
  hardware.enableRedistributableFirmware = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Brisbane";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "dqb";
  services.desktopManager.plasma6.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,kr";
    variant = "";
    options = "caps:escape,korean:ralt_hangul,korean:rctrl_hanja";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
  services.pipewire.wireplumber.extraConfig."11-bluetooth-policy" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = false;
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dqb = {
    isNormalUser = true;
    description = "daqoblade";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };
  security.sudo.extraRules = [
   {
    users = ["dqb"];
    commands = [
     {
      command = "ALL";
      options = ["NOPASSWD"];
     }
    ];
   }
  ];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/0e7b0dd5-42b3-4cc0-baf1-78130c938cb7";
    fsType = "ext4";
    options = [ "nofail" ];
};

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellInit = ''
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^[[OA' history-substring-search-backward
      bindkey '^[[OB' history-substring-search-forward
    '';
    interactiveShellInit = "source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh";
  };
  programs.niri.enable = true;
  users.users.dqb.shell = pkgs.zsh;
  # Install firefox.
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.variables = {
    XCURSOR_THEME = "Rin";
    XCURSOR_SIZE = "24";
  };
  environment.systemPackages = with pkgs; [
  vim-full
  #  wget
  vesktop
  helix
  usb-modeswitch
  
  emacs
  git
  ripgrep
  fd

  opentabletdriver
  obs-studio

  thunderbird
  kdePackages.okular
  foliate

  heroic
  mangohud
  gamemode
  
  niri
  foot
  fuzzel
  fastfetch
  grim
  nwg-panel
  nwg-drawer
  xwayland-satellite
  xorg.xhost
  slurp
  wl-clipboard
  mako
  usbutils
  ];
  systemd.user.services.disable-middle-click-paste = {
    description = "Disable middle-click paste by clearing primary selection";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --primary --watch ${pkgs.wl-clipboard}/bin/wl-copy --primary --clear";
      Restart = "always";
      RestartSec = 1;
    };
  };
  programs.gamemode.enable = true;
  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;
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
  console.useXkbConfig = true;
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-hangul
      fcitx5-gtk
    ];
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1"; 
  };
  
  fonts = {
    packages = with pkgs; [
      nanum         # Classic Korean font
      noto-fonts
      meslo-lgs-nf
      noto-fonts-cjk-sans # High-quality Google/Adobe Korean font
      noto-fonts-cjk-serif
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif CJK KR" "NanumMyeongjo" ];
      sansSerif = [ "Noto Sans CJK KR" "NanumGothic" ];
      monospace = [ "Noto Sans Mono CJK KR" ];
    };
  };
  environment.variables = {
    DISPLAY = ":0";
  };
  fonts.fontconfig.hinting.enable = true;
  fonts.fontconfig.antialias = true;
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>serif</family>
        <prefer><family>Noto Serif CJK KR</family></prefer>
      </alias>
      <alias>
        <family>sans-serif</family>
        <prefer><family>Noto Sans CJK KR</family></prefer>
      </alias>
      <alias>
        <family>monospace</family>
        <prefer><family>Noto Sans Mono CJK KR</family></prefer>
      </alias>
    </fontconfig>
'';

  networking.localCommands = ''
    ip link set wlp41s0 down
  '';
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
