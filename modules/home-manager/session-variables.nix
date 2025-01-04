{ lib, config, pkgs, ... }:

{
  config = {
    home.sessionVariables = {
      FLAKE="/home/tobias/nixos";
      EDITOR="vim";
    };
  };
}
