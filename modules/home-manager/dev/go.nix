{ lib, config, pkgs, ... }:

{
  options.my.dev.go = {
    enable = lib.mkEnableOption "enable go development environment";
  };

  config = lib.mkIf config.my.dev.go.enable {
    home.packages = with pkgs; [
      go
    ];
  };
}
