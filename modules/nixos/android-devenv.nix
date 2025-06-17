{ lib, config, pkgs, ... }:

{
  options.my.dev.android = {
    enable = lib.mkEnableOption "enable android dev environment";
  };

  config = lib.mkIf config.my.dev.android.enable {
    users.groups.plugdev = {};

    users.users.tobias.extraGroups = [ "adbusers" "plugdev" ];

    programs.adb.enable = true;
    environment.systemPackages = with pkgs; [
      android-studio
    ];

    services.udev.packages = [
      pkgs.android-udev-rules
    ];
  };
}
