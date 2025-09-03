{ lib, config, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      vim
      wget
      tree
      fd
      ripgrep
      git
      stow
      eza
      ncdu
      tmux
      nh
      dig
      nmap
      tcpdump
      clamav
      clamtk
      gptfdisk
      zfs
      smartmontools
      # ventoy
      exfat
      exfatprogs
      dmidecode
    ];

    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      acl
      attr
      bzip2
      dbus
      expat
      fontconfig
      freetype
      fuse3
      icu
      libnotify
      libsodium
      libssh
      libunwind
      libusb1
      libuuid
      nspr
      nss
      stdenv.cc.cc
      util-linux
      zlib
      zstd
    ] ++ lib.optionals (config.hardware.graphics.enable) [
      pipewire
      cups
      libxkbcommon
      pango
      mesa
      libdrm
      libglvnd
      libpulseaudio
      atk
      cairo
      alsa-lib
      at-spi2-atk
      at-spi2-core
      gdk-pixbuf
      glib
      gtk3
      libGL
      libappindicator-gtk3
      vulkan-loader
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxkbfile
      xorg.libxshmfence
    ];

    # Install firefox.
    programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
    };

    fonts.packages = with pkgs; [
      raleway
    ];
  };
}
