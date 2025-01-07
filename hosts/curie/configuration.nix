# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../modules/nixos/system-programs.nix
      ./../../modules/nixos/build-essentials.nix
      ./../../modules/nixos/main-user.nix
      ./../../modules/nixos/additional-users.nix
      ./../../modules/nixos/container.nix
      ./../../modules/nixos/desktop.nix
      ./../../modules/nixos/portable.nix
      ./../../modules/nixos/my-steam.nix
      ./../../modules/nixos/android-devenv.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home-manager = {
    backupFileExtension = "backup";
    # also pass inputs to home-manager modules
    extraSpecialArgs = {inherit inputs;};
    users = {
      "tobias" = import ./home.nix;
    };
  };

  my-portable.enable = true;
  my-steam.enable = false;
  my-container.enable = true;
  additional-users.valerie.enable = false;
  android-devenv.enable = false;

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    devices = [ "nodev" ];
    useOSProber = true;
    efiSupport = true;
  };

  networking.hostName = "curie"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # needed for wireguard client through network manager
  networking.firewall.checkReversePath = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
