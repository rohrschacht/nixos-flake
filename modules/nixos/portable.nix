{ lib, config, pkgs, ... }:

{
  options.my-portable = {
    enable = lib.mkEnableOption "enable portable configuration";
  };

  config = lib.mkIf config.my-portable.enable {
    # services.logind.extraConfig = ''
    #   HandleLidSwitch=lock
    #   HandleLidSwitchDocked=ignore
    # '';
    services.logind = {
      lidSwitch = "lock";
      lidSwitchDocked = "ignore";
    };
  };
}
