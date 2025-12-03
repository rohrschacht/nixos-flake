
{ lib, config, pkgs, ... }:

{
  config = {
    home.file.".config/ghostty/config" = {
      source = ./configs/ghostty/config;
      recursive = true;
    };
  };
}
