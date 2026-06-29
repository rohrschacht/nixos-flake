{ lib, config, pkgs, ... }:

{
  options.my.dev.android = {
    enable = lib.mkEnableOption "enable android dev environment";
  };

  config = lib.mkIf config.my.dev.android.enable {
    users.groups.plugdev = {};

    users.users.tobias.extraGroups = [ "adbusers" "plugdev" ];

    environment.systemPackages = with pkgs; [
      android-tools
      android-studio
    ];

    services.udev.packages = [
      pkgs.android-udev-rules
    ];
  };
}
