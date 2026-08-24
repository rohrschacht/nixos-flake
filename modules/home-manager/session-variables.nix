{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = {
    home.sessionVariables = {
      NH_FLAKE = "/home/tobias/nixos";
      EDITOR = "nvim";
      NVIM_APPNAME = "lazyvim";
    };
  };
}
