{ lib, config, pkgs, ... }:

{
  options.additional-users = {
    valerie.enable = lib.mkEnableOption "enable valerie user";
  };

  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.valerie = lib.mkIf config.additional-users.valerie.enable {
      isNormalUser = true;
      description = "Valerie";
      extraGroups = [ "networkmanager" ];
      initialPassword = "initialPassword";
    };
  };
}
