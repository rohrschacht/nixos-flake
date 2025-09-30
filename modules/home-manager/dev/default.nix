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
      devenv
      awscli2
      lazygit
      devcontainer
      pre-commit
      neovim
      nerd-fonts.symbols-only
    ] ++ [
      # inputs.nixpkgs-pinned.legacyPackages.${system}.devenv
    ];

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
