{ lib, config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    gcc
    cmake
    pkg-config

    clang-tools
  ];
}
