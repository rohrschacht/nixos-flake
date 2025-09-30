{ lib, config, pkgs, ... }:

{
  config = {
    home.sessionVariables = {
      NH_FLAKE="/home/tobias/nixos";
      EDITOR="vim";
      NVIM_APPNAME="lazyvim";
    };
  };
}
