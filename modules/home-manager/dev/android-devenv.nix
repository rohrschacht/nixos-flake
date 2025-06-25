{ lib, config, pkgs, ... }:

{
  options.my.dev.android-devenv = {
    enable = lib.mkEnableOption "enable scripts for creating an android devenv";
  };

  config = lib.mkIf config.my.dev.android-devenv.enable {

    home.packages = with pkgs; [
        (pkgs.writeShellScriptBin "create-android-devenv"
            ''
devenv init

cat <<EOF >devenv.yaml
${(builtins.readFile ./templates/android/devenv.yaml)}
EOF
cat <<EOF >devenv.nix
${(builtins.readFile ./templates/android/devenv.nix)}
EOF
            ''
        )
    ];
  };
}
