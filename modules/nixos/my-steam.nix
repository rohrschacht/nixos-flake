{ lib, config, pkgs, ... }:

{
  options.my-steam = {
    enable = lib.mkEnableOption "enable steam";
  };

  config = lib.mkIf config.my-steam.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };

    programs.gamemode.enable = true;
    # activate in steam game launch options using:
    # gamemoderun %command%
    # gamescope %command%
  };
}
