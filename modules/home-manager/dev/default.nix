{ lib, config, pkgs, inputs, ... }:

{
  imports = [
    ./android-devenv.nix
    ./android.nix
    ./cpp.nix
    ./go.nix
    ./jsts.nix
    ./neovim.nix
    ./py.nix
    ./rust.nix
  ];

  config = {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      gnumake
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

    home.file.".config/lazygit/config.yml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/modules/home-manager/configs/lazygit/config.yml";

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
