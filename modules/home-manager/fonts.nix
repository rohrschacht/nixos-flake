{ lib, config, pkgs, ... }:

let
  nordwand-mono = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "nordwand-mono";
    version = "1.3.4";
    src = pkgs.fetchzip {
      url = "https://github.com/tywr/Nordwand-Mono/releases/download/${version}/NordwandMono-TTF.zip";
      stripRoot = false;
      hash = "sha256-PnWIg43vKHbSDk68YfH0NafqGDCZym8440aK/ouhOLw=";
    };
    installPhase = ''
      install -Dm644 -t $out/share/fonts/truetype *.ttf
    '';
  };
in
{
  config = {
    fonts.fontconfig.enable = true;

    home.packages = (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      martian-mono
      raleway
    ]) ++ (with pkgs.nerd-fonts; [
      dejavu-sans-mono
      fira-code
      fira-mono
      hack
      inconsolata
      iosevka
      jetbrains-mono
      ubuntu-mono
    ]) ++ [
      nordwand-mono
    ];
  };
}
