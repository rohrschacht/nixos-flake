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
      bitwarden
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
      yubikey-personalization-gui
      yubikey-manager
      wireshark
      wl-clipboard
      libsecret
      yubioath-flutter
      ghostty
      yazi
    ] ++ [
      inputs.nixpkgs-unstable.legacyPackages.${system}.rclone
    ];

    programs.btop = {
      enable = true;
    };
  };
}
