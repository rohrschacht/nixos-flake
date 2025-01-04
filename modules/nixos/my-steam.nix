{ lib, config, pkgs, ... }:

{
  options.my-steam = {
    enable = lib.mkEnableOption "enable steam";
  };

  config = lib.mkIf config.my-steam.enable {
    programs.steam = {
      enable = true;
    };
  };
}
