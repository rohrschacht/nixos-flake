{ lib, config, pkgs, inputs, ... }:

{
  config = {
    home.packages = with pkgs; [
      neovim
      ansible-lint
      statix
    ] ++ [
      inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system}.tree-sitter
    ];

    home.file.".config/lazyvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home-manager/configs/lazyvim";
  };
}
