{ lib, config, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      gnumake
      gcc
    ];
  };
}
