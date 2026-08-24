{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # toKDL shape for `bind "<key>" { <action>; ... }`
  mkBind = key: actions: {
    bind = {
      _args = [ key ];
      _children = actions;
    };
  };
in
{
  config = {
    programs.zellij = {
      enable = true;
      package = pkgs-unstable.zellij;
      exitShellOnExit = true;
      enableFishIntegration = true;

      # Additive to zellij's built-in defaults: no `clear-defaults`, so every
      # default keybinding still applies. Alt+t and Alt+1..9 are unbound by
      # default in 0.45, so nothing is displaced.
      settings = {
        show_startup_tips = false;

        keybinds._children = [
          {
            shared_except = {
              _args = [ "locked" ];
              _children =
                [ (mkBind "Alt t" [ { NewTab = { }; } ]) ]
                ++ map (i: mkBind "Alt ${toString i}" [ { GoToTab._args = [ i ]; } ]) (lib.range 1 9);
            };
          }
        ];
      };
    };
  };
}
