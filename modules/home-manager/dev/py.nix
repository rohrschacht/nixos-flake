{ lib, config, pkgs, ... }:

{
  options.my.dev.py = {
    enable = lib.mkEnableOption "enable python development environment";
  };

  config = lib.mkIf config.my.dev.py.enable {
    home.packages = with pkgs; [
      python3
      poetry
    ];
  };
}
