{ lib, config, pkgs, ... }:

{
  config = {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;

      # Extensions
      extensions = (with pkgs.vscode-extensions; [
        bbenoist.nix
      ]);
    };
  };
}
