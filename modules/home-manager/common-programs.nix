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
      tlrc
      file
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
      ausweisapp
      ffmpeg
      tenacity
      gcolor3
      dos2unix
    ] ++ [
      inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.rclone
    ];

    programs = {
      btop = {
        enable = true;
      };

      bat.enable = true;

      yazi = {
        enable = true;
        enableFishIntegration = true;

        keymap = {
          mgr.prepend_keymap = [
            { on = "!"; for = "unix"; run = "shell $SHELL --block"; desc = "Open $SHELL here"; }
          ];
        };
      };

      zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [
          "--cmd j"
        ];
      };
    };

    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
