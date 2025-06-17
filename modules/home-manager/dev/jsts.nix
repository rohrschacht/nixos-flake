{ lib, config, pkgs, ... }:

{
  options.my.dev.jsts = {
    enable = lib.mkEnableOption "enable js/ts development environment";
  };

  config = lib.mkIf config.my.dev.jsts.enable {
    home.packages = with pkgs; [
      deno
      nodejs_20
    ];
  };
}
