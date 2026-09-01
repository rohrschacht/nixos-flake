{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  zellij-unstable = pkgs-unstable.zellij;
in
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
        libinput
        speedtest-cli
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
        # yazi < 26.8 hard-codes "inside zellij => sixel only", which lands on
        # chafa here; newer yazi picks the kgp-old driver zellij 0.45 supports.
        package = pkgs-unstable.yazi;
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
            {
              on = "<C-/>";
              run = ''
                shell --orphan -- ${zellij-unstable}/bin/zellij run \
                  --floating --close-on-exit \
                  --name "sh: ''${PWD##*/}" \
                  --cwd "$PWD" -- $SHELL
              '';
              desc = "Floating shell here";
            }
            {
              # terminals without CSI-u send Ctrl+/ as 0x1F
              on = "<C-_>";
              run = ''
                shell --orphan -- ${zellij-unstable}/bin/zellij run \
                  --floating --close-on-exit \
                  --name "sh: ''${PWD##*/}" \
                  --cwd "$PWD" -- $SHELL
              '';
              desc = "Floating shell here";
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
