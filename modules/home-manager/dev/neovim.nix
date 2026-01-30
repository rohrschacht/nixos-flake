{ lib, config, pkgs, inputs, ... }:

{
  config = {
    home.packages = with pkgs; [
      neovim
      ansible-lint
      statix
    ];
  };
}
