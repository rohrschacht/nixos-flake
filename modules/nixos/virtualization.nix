{ lib, config, pkgs, ... }:

{
  options.my-virt = {
    enable = lib.mkEnableOption "enable qemu/kvm";
  };
  config = lib.mkIf config.my-virt.enable {
    programs.virt-manager.enable = true;
    
    virtualisation.libvirtd.enable = true;

    virtualisation.spiceUSBRedirection.enable = true;
    
    users.groups.libvirtd.members = ["tobias"];
  };
}
