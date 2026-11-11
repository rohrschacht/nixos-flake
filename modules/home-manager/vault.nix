{
  lib,
  config,
  pkgs,
  ...
}:

# gocryptfs vault: plaintext view at `mountPoint`, ciphertext in the Nextcloud
# folder so it gets synced/backed up encrypted. Mounted at login by a systemd
# user service using a keyfile. The password and the master key printed by
# `gocryptfs -init` belong in Bitwarden as the recovery copy.
#
# One-time setup:
#   mkdir -p ~/.config/gocryptfs ~/Nextcloud/Vault.enc
#   (umask 077; head -c 32 /dev/urandom | base64 -w0 > ~/.config/gocryptfs/vault.pass)
#   gocryptfs -init -passfile ~/.config/gocryptfs/vault.pass ~/Nextcloud/Vault.enc
#   systemctl --user start gocryptfs-vault
let
  cfg = config.my.vault;
  home = config.home.homeDirectory;
in
{
  options.my.vault = {
    enable = lib.mkEnableOption "gocryptfs vault synced via Nextcloud";
    cipherDir = lib.mkOption {
      type = lib.types.str;
      default = "${home}/Nextcloud/Vault.enc";
      description = "encrypted gocryptfs directory (inside the Nextcloud sync folder)";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "${home}/Vault";
      description = "where the decrypted view is mounted";
    };
    passFile = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.config/gocryptfs/vault.pass";
      description = "keyfile holding the gocryptfs password";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gocryptfs ];

    systemd.user.services.gocryptfs-vault = {
      Unit = {
        Description = "gocryptfs vault ${cfg.mountPoint}";
        # skip silently until the one-time setup above has been done
        ConditionPathExists = [
          cfg.passFile
          "${cfg.cipherDir}/gocryptfs.conf"
        ];
      };
      Service = {
        Type = "simple";
        # gocryptfs shells out to the setuid fusermount wrapper
        Environment = "PATH=/run/wrappers/bin";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.mountPoint}";
        ExecStart = "${pkgs.gocryptfs}/bin/gocryptfs -fg -nosyslog -passfile ${cfg.passFile} ${cfg.cipherDir} ${cfg.mountPoint}";
        ExecStop = "/run/wrappers/bin/fusermount -u ${cfg.mountPoint}";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
