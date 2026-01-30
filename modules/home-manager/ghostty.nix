
{ lib, config, pkgs, ... }:

{
  config = {
    programs.ghostty.enable = true;

    home.file.".config/ghostty/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home-manager/configs/ghostty/config";
  };
}
