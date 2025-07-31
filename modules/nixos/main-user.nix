{ lib, config, pkgs, ... }:

{
  config = {
    programs.fish.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.tobias = {
      isNormalUser = true;
      description = "Tobias";
      extraGroups = [ "networkmanager" "wheel" "docker" "adm" "podman" ];
      shell = pkgs.fish;
    };
  };
}
