{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

{
  config = {
    programs.gpg.enable = true;
    programs.gpg.scdaemonSettings = {
      disable-ccid = true;
    };
    services.gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;

      defaultCacheTtl = 60 * 60 * 6;
      defaultCacheTtlSsh = 60 * 60 * 6;

      enableFishIntegration = true;
      enableScDaemon = true;

      pinentry.package = pkgs.pinentry-gnome3;
    };
  };
}
