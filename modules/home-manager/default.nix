{ lib, config, pkgs, ... }:

{
  imports = [
    ./dev
    ./admin-utils.nix
    ./common-programs.nix
    ./fish.nix
    ./fonts.nix
    ./ghostty.nix
    ./git.nix
    ./gnome.nix
    ./session-variables.nix
    ./vscode.nix
  ];
}
