{ lib, config, pkgs, ... }:

{
  imports = [
    ./common-programs.nix
    ./gnome.nix
    ./admin-utils.nix
    ./git.nix
    ./fish.nix
    ./dev
    ./vscode.nix
    ./session-variables.nix
  ];
}
