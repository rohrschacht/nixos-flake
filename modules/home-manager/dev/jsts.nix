{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  options.my.dev.jsts = {
    enable = lib.mkEnableOption "enable js/ts development environment";
  };

  config = lib.mkIf config.my.dev.jsts.enable {
    home.packages =
      with pkgs;
      [
        deno
        nodejs
        postgresql
      ]
      ++ [
        pkgs-unstable.pnpm
      ];
  };
}
