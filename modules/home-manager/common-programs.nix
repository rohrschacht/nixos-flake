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
      jq
      yq
      sqlite
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
      xournalpp
      ytmdesktop
    ] ++ [
      inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.rclone
    ];

    programs.btop = {
      enable = true;
    };

    programs.bat.enable = true;

    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
    };

    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
