{ lib, config, pkgs, ... }:

{
  imports = [
    ./jsts-devenv.nix
    ./go-devenv.nix
    ./py-devenv.nix
    ./android-devenv.nix
  ];

  config = {
    home.packages = with pkgs; [
      jetbrains-toolbox
      direnv
      fh
      devenv
    ];

    home.sessionVariables = {
      DIRENV_WARN_TIMEOUT="5m";
    };

    go-devenv.enable = lib.mkDefault true;
    jsts-devenv.enable = lib.mkDefault true;
    py-devenv.enable = lib.mkDefault true;
    android-devenv.enable = lib.mkDefault true;
  };
}
