{ lib, config, pkgs, inputs, ... }:

{
  imports = [
    ./jsts.nix
    ./go.nix
    ./rust.nix
    ./py.nix
    ./android.nix
    ./android-devenv.nix
  ];

  config = {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      jetbrains-toolbox
      direnv
      fh
      # devenv
      awscli2
      lazygit
      devcontainer
      pre-commit
      neovim
      nerd-fonts.symbols-only
      devpod-desktop
    ] ++ [
      # inputs.nixpkgs-pinned.legacyPackages.${stdenv.hostPlatform.system}.devenv
    ];


    home.file.".config/lazygit/config.yml" = {
      source = ../configs/lazygit/config.yml;
      recursive = true;
    };

    home.sessionVariables = {
      DIRENV_WARN_TIMEOUT="5m";
    };

    my.dev.go.enable = lib.mkDefault true;
    my.dev.rust.enable = lib.mkDefault true;
    my.dev.jsts.enable = lib.mkDefault true;
    my.dev.py.enable = lib.mkDefault true;
    my.dev.android.enable = lib.mkDefault true;
    my.dev.android-devenv.enable = lib.mkDefault true;
  };
}
