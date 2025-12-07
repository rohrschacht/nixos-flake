
{ lib, config, pkgs, ... }:

{
  config = {
    programs.ghostty.enable = true;

    home.file.".config/ghostty/config" = {
      source = ./configs/ghostty/config;
      recursive = true;
    };
  };
}
