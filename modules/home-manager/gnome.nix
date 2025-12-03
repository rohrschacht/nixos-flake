{ lib, config, pkgs, ... }:

let
  browser = "firefox.desktop";
  imgviewer = "org.gnome.Loupe.desktop";
  pdfviewer = "org.gnome.Evince.desktop";
in
{
  config = {
    # from:
    # https://nixos.wiki/wiki/GNOME
    # https://heywoodlh.io/nixos-gnome-settings-and-keyboard-shortcuts

    home.packages = with pkgs; [
      gnomeExtensions.appindicator
      gnomeExtensions.system-monitor
      gnomeExtensions.caffeine
    ];

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ "${browser}" ];
      "x-scheme-handler/https" = [ "${browser}" ];
      "x-scheme-handler/chrome" = [ "${browser}" ];
      "text/html" = [ "${browser}" ];
      "application/x-extension-htm" = [ "${browser}" ];
      "application/x-extension-html" = [ "${browser}" ];
      "application/x-extension-shtml" = [ "${browser}" ];
      "application/xhtml+xml" = [ "${browser}" ];
      "application/x-extension-xhtml" = [ "${browser}" ];
      "application/x-extension-xht" = [ "${browser}" ];

      "image/jpeg" = [ "${imgviewer}" ];
      "image/png" = [ "${imgviewer}" ];
      "image/gif" = [ "${imgviewer}" ];
      "image/webp" = [ "${imgviewer}" ];
      "image/tiff" = [ "${imgviewer}" ];
      "image/x-tga" = [ "${imgviewer}" ];
      "image/vnd-ms.dds" = [ "${imgviewer}" ];
      "image/x-dds" = [ "${imgviewer}" ];
      "image/bmp" = [ "${imgviewer}" ];
      "image/vnd.microsoft.icon" = [ "${imgviewer}" ];
      "image/vnd.radiance" = [ "${imgviewer}" ];
      "image/x-exr" = [ "${imgviewer}" ];
      "image/x-portable-bitmap" = [ "${imgviewer}" ];
      "image/x-portable-graymap" = [ "${imgviewer}" ];
      "image/x-portable-pixmap" = [ "${imgviewer}" ];
      "image/x-portable-anymap" = [ "${imgviewer}" ];
      "image/x-qoi" = [ "${imgviewer}" ];
      "image/svg+xml" = [ "${imgviewer}" ];
      "image/svg+xml-compressed" = [ "${imgviewer}" ];
      "image/avif" = [ "${imgviewer}" ];
      "image/heic" = [ "${imgviewer}" ];
      "image/jxl" = [ "${imgviewer}" ];

      "application/pdf" = [ "${pdfviewer}" ];

      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "onlyoffice-desktopeditors.desktop" ];

      "text/markdown" = [ "org.gnome.TextEditor.desktop" ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
    };

    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = with pkgs.gnomeExtensions; [
            appindicator.extensionUuid
            system-monitor.extensionUuid
            caffeine.extensionUuid
          ];
          favorite-apps = ["nautilus.desktop" "firefox.desktop" "thunderbird.desktop" "org.gnome.Console.desktop"];
        };
        "org/gnome/settings-daemon/plugins/power" = {
          ambient-enabled = false;
          sleep-inactive-ac-type = "nothing";
        };
        "org/gnome/desktop/wm/preferences" = {
          num-workspaces = 5;
        };
        "org/gnome/desktop/interface" = {
          clock-show-seconds = true;
          clock-show-weekday = true;
          # color-scheme = "prefer-dark";
          enable-hot-corners = false;
          # font-antialiasing = "grayscale";
          # font-hinting = "slight";
          # gtk-theme = "Nordic";
          # toolkit-accessibility = true;
          show-battery-percentage = true;
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          click-method = "areas";
          two-finger-scrolling-enabled = true;
        };
        "org/gnome/mutter" = {
          edge-tiling = true;
          workspaces-only-on-primary = true;
          dynamic-workspaces = false;
        };
        "org/gnome/settings-daemon/plugins/color" = {
          night-light-enabled = true;
        };
        "org/gnome/shell/keybindings" = {
          switch-to-application-1 = [ "disabled" ];
          switch-to-application-2 = [ "disabled" ];
          switch-to-application-3 = [ "disabled" ];
          switch-to-application-4 = [ "disabled" ];
          switch-to-application-5 = [ "disabled" ];
        };
        "org/gnome/desktop/wm/keybindings" = {
          # activate-window-menu = "disabled";
          # toggle-message-tray = "disabled";
          close = ["<Super>x"];
          # maximize = "disabled";
          # minimize = ["<Super>comma"];
          # move-to-monitor-down = "disabled";
          # move-to-monitor-left = "disabled";
          # move-to-monitor-right = "disabled";
          # move-to-monitor-up = "disabled";
          # move-to-workspace-down = "disabled";
          # move-to-workspace-up = "disabled";
          # toggle-maximized = ["<Super>m"]';
          # unmaximize = "disabled";
          move-to-workspace-1 = ["<Shift><Super>1"];
          move-to-workspace-2 = ["<Shift><Super>2"];
          move-to-workspace-3 = ["<Shift><Super>3"];
          move-to-workspace-4 = ["<Shift><Super>4"];
          move-to-workspace-5 = ["<Shift><Super>5"];
          switch-to-workspace-1 = ["<Super>1"];
          switch-to-workspace-2 = ["<Super>2"];
          switch-to-workspace-3 = ["<Super>3"];
          switch-to-workspace-4 = ["<Super>4"];
          switch-to-workspace-5 = ["<Super>5"];
          switch-applications = ["<Super>Tab" "<Alt>Tab"];
          switch-applications-backward = ["<Shift><Super>Tab" "<Shift><Alt>Tab"];
          cycle-windows = ["<Super>j"];
          cycle-windows-backward = ["<Super>k"];
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          email = ["<Super>c"];
          home = ["<Super>e"];
          www = ["<Super>b"];
          # next = [ "<Shift><Control>n" ];
          # previous = [ "<Shift><Control>p" ];
          # play = [ "<Shift><Control>space" ];
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          #   "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          #   "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          #   "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          name = "terminal";
          command = "ghostty";
          binding = "<Super>Return";
        };
        # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        #   name = "kitty ctrl_alt";
        #   command = "kitty -e tmux";
        #   binding = "<Ctrl><Alt>t";
        # };
        # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        #   name = "rofi-rbw";
        #   command = "rofi-rbw --action copy";
        #   binding = "<Ctrl><Super>s";
        # };
        # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        #   name = "rofi launcher";
        #   command = "rofi -theme nord -show run -display-run 'run: '";
        #   binding = "<Super>space";
        # };
      };
    };

    xdg.configFile."autostart/gnome-keyring-ssh.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=SSH Key Agent
        Comment=GNOME Keyring: SSH Agent
        Exec=/run/wrappers/bin/gnome-keyring-daemon --start --components=ssh
        OnlyShowIn=GNOME;Unity;MATE;
        X-GNOME-Autostart-Phase=PreDisplayServer
        X-GNOME-AutoRestart=false
        X-GNOME-Autostart-Notify=true
        Hidden=true
      '';
    };
  };
}
