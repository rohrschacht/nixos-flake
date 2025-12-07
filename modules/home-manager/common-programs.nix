{ lib, config, pkgs, inputs, ... }:

{
  config = {
    home.packages = with pkgs; [
      thunderbird
      google-chrome
      discord
      signal-desktop
      qalculate-gtk
      gimp
      inkscape
      bitwarden-desktop
      filezilla
      ferdium
      libreoffice
      onlyoffice-desktopeditors
      vlc
      zoom-us
      todoist-electron
      lf
      jq
      yq
      sqlite
      gnupg
      nextcloud-client
      bat
      keepassxc
      remmina
      drawio
      imagemagick
      pdfarranger
      yubikey-manager
      wireshark
      wl-clipboard
      libsecret
      yubioath-flutter
      ghostty
      yazi
      xournalpp
    ] ++ [
      inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.rclone
    ];

    programs.btop = {
      enable = true;
    };
  };
}
