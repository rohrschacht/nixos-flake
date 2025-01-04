{ lib, config, pkgs, ... }:

{
  options.go-devenv = {
    enable = lib.mkEnableOption "enable go development environment";
  };

  config = lib.mkIf config.go-devenv.enable {
    home.packages = with pkgs; [
      go
    ];
  };
}
