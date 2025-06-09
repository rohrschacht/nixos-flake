{ lib, config, pkgs, ... }:

{
  config = {
    programs.vscode = {
      enable = true;
      profiles.default.enableUpdateCheck = false;
      profiles.default.enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;

      # Extensions
      profiles.default.extensions = (with pkgs.vscode-extensions; [
        bbenoist.nix
      ]);
    };
  };
}
