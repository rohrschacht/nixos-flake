{ lib, config, pkgs, ... }:

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
      sqlite
      gnupg
      nextcloud-client
      bat
      keepassxc
      remmina
      drawio
      imagemagick
    ];

    programs.btop = {
      enable = true;
    };
  };
}
