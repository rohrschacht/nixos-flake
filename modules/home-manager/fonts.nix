{ lib, config, pkgs, ... }:

{
  config = {
    fonts.fontconfig.enable = true;

    home.packages = (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      raleway
    ]) ++ (with pkgs.nerd-fonts; [
      dejavu-sans-mono
      fira-code
      fira-mono
      hack
      inconsolata
      jetbrains-mono
    ]);
  };
}
