{ lib, config, pkgs, ... }:

{
  imports = [
    ./system-programs.nix
    ./build-essentials.nix
    ./main-user.nix
    ./additional-users.nix
    ./container.nix
    ./virtualization.nix
    ./desktop.nix
    ./portable.nix
    ./my-steam.nix
    ./android-devenv.nix
  ];
}
