{ lib, config, pkgs, ... }:

{
  options.my.dev.rust = {
    enable = lib.mkEnableOption "enable rust development environment";
  };

  config = lib.mkIf config.my.dev.rust.enable {
    home.packages = with pkgs; [
      rustup
    ];
  };
}
