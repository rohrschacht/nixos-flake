{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = {
    programs.kitty = {
      enable = true;
      themeFile = "adwaita_dark";

      font = {
        name = "Hack Nerd Font Mono";
        size = 10;
      };

      shellIntegration.mode = "no-cursor";

      # Mirrors configs/ghostty/config where kitty has an equivalent.
      settings = {
        # ghostty's "Adwaita Dark" palette; kitty-themes' adwaita_dark (above,
        # kept for tab/border colors) uses different terminal colors.
        # Settings come after the theme include, so these win.
        background = "#1d1d20";
        foreground = "#ffffff";
        cursor = "#ffffff";
        cursor_text_color = "#1d1d20";
        selection_background = "#ffffff";
        selection_foreground = "#5e5c64";
        color0 = "#241f31";
        color1 = "#c01c28";
        color2 = "#2ec27e";
        color3 = "#f5c211";
        color4 = "#1e78e4";
        color5 = "#9841bb";
        color6 = "#0ab9dc";
        color7 = "#c0bfbc";
        color8 = "#5e5c64";
        color9 = "#ed333b";
        color10 = "#57e389";
        color11 = "#f8e45c";
        color12 = "#51a1ff";
        color13 = "#c061cb";
        color14 = "#4fd2fd";
        color15 = "#f6f5f4";

        cursor_shape = "block";
        cursor_blink_interval = 0;

        clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
        # default also has `confirm`; ghostty runs with paste protection off
        paste_actions = "quote-urls-at-prompt";

        background_opacity = "0.9";
        background_blur = 20;

        scrollback_lines = 100000;
        # in MB, roughly ghostty's 10_000_000 byte scrollback-limit
        scrollback_pager_history_size = 10;

        enabled_layouts = "splits,stack";
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        confirm_os_window_close = 0;

        # stash tabs holding hidden floats (float.py) stay out of the tab bar
        tab_bar_filter = "not title:^__float_stash_";
        watcher = "float.py";
        # title bar only on floats: window_title_bar.py returns "" otherwise
        window_title_bar_min_windows = 2;
        window_title_template = "{custom}";

        # `kitten @` from fish (inf work) and yazi (orphaned, no tty) reach
        # kitty through the socket exported as $KITTY_LISTEN_ON.
        allow_remote_control = "yes";
        listen_on = "unix:@kitty-{kitty_pid}";
      };

      # Alt shortcuts modelled on zellij's. `--cwd=current` on every launch
      # also makes new windows inside `kitten ssh` open on the remote host.
      keybindings = {
        # new float when a float is focused (like zellij), else a split
        "alt+n" = "kitten float.py new_or_split";
        "alt+d" = "launch --location=vsplit --cwd=current";
        "alt+shift+d" = "launch --location=hsplit --cwd=current";

        "alt+h" = "kitten float.py focus left";
        "alt+j" = "kitten float.py focus down";
        "alt+k" = "kitten float.py focus up";
        "alt+l" = "kitten float.py focus right";
        "alt+left" = "kitten float.py focus left";
        "alt+down" = "kitten float.py focus down";
        "alt+up" = "kitten float.py focus up";
        "alt+right" = "kitten float.py focus right";

        "alt+shift+h" = "move_window left";
        "alt+shift+j" = "move_window down";
        "alt+shift+k" = "move_window up";
        "alt+shift+l" = "move_window right";

        "alt+equal" = "resize_window wider";
        "alt+minus" = "resize_window narrower";
        "alt+shift+equal" = "resize_window taller";
        "alt+shift+minus" = "resize_window shorter";

        "alt+x" = "close_window";
        "alt+z" = "toggle_layout stack";
        "alt+right_bracket" = "next_layout";
        # zellij-style floating panes, see configs/kitty/float.py
        "alt+f" = "kitten float.py toggle";
        "alt+shift+f" = "kitten float.py cycle";

        "alt+t" = "launch --type=tab --cwd=current";
        "alt+r" = "set_tab_title";
      }
      // lib.listToAttrs (
        map (i: lib.nameValuePair "alt+${toString i}" "goto_tab ${toString i}") (lib.range 1 9)
      );
    };

    # `kitten ssh` (the fish `ssh` alias) runs its bootstrap as an ssh command,
    # so the remote starts a non-interactive `bash -c` first, which Debian's
    # bash still feeds ~/.bashrc; dotfiles that export a "sourced" guard there
    # (flatsat: BASHRC_SOURCED) then skip .bashrc in the real login shell.
    # The inherited `no-rc` (Home Manager sources the fish integration itself)
    # would also leave remote shells without kitty's shell integration.
    xdg.configFile."kitty/ssh.conf".text = ''
      shell_integration no-cursor
      env BASHRC_SOURCED
    '';

    # Kittens and the title bar hook are plain Python, kept next to the
    # ghostty config; kitty loads them from ~/.config/kitty.
    xdg.configFile."kitty/float.py".source = ./configs/kitty/float.py;
    xdg.configFile."kitty/window_title_bar.py".source = ./configs/kitty/window_title_bar.py;
  };
}
