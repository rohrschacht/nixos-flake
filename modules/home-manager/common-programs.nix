{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

{
  config = {
    home.packages =
      with pkgs;
      [
        thunderbird
        google-chrome
        discord
        qalculate-gtk
        gimp
        inkscape
        # bitwarden-desktop
        filezilla
        ferdium
        # telegram-desktop
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
        # ytmdesktop
        ausweisapp
        ffmpeg
        tenacity
        gcolor3
        dos2unix
        kdePackages.gwenview
        borgbackup
        borgmatic
      ]
      ++ [
        inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.rclone
        inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.telegram-desktop
        inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.signal-desktop
      ];

    programs = {
      btop = {
        enable = true;
      };

      bat.enable = true;

      yazi = {
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "y";

        keymap = {
          mgr.prepend_keymap = [
            {
              on = "!";
              for = "unix";
              run = "shell $SHELL --block";
              desc = "Open $SHELL here";
            }
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
