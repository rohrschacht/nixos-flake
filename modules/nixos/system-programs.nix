{ lib, config, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      vim
      wget
      tree
      fd
      ripgrep
      git
      stow
      eza
      ncdu
      tmux
      nh
      dig
      nmap
      tcpdump
      clamav
      clamtk
      gptfdisk
      # ventoy
    ];

    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      # add any missing dynamic libraries here
    ];

    # Install firefox.
    programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
    };

    fonts.packages = with pkgs; [
      raleway
    ];
  };
}
