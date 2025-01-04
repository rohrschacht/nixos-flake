{ lib, config, pkgs, ... }:

{
  options.py-devenv = {
    enable = lib.mkEnableOption "enable python development environment";
  };

  config = lib.mkIf config.py-devenv.enable {
    home.packages = with pkgs; [
      python3
      poetry
    ];
  };
}
