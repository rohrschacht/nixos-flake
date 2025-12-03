{ lib, config, pkgs, ... }:

{
  config = {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs.nerd-fonts; [
      dejavu-sans-mono
      fira-code
      fira-mono
      hack
      inconsolata
      jetbrains-mono
    ];
  };
}
