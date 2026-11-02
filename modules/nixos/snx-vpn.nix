{ lib, config, pkgs, ... }:

let
  # Check Point SNX only supports FHS distros, so it lives in an Ubuntu distrobox.
  # Rootful because snx needs to create the tun device; the box shares the host network.
  boxName = "snx-vpn";
  boxHome = "${config.users.users.tobias.home}/.local/share/distrobox-homes/${boxName}";
  # Site-specific values are kept out of the repo, in a file in the user's config dir:
  #   PORTAL=https://portal.example.com
  #   DNS_SERVERS="10.0.0.1 10.0.0.2"
  envFile = "${config.users.users.tobias.home}/.config/snx-vpn/env";
  user = config.users.users.tobias.name;

  # Runs as root on every box start; reached via the host root mounted at /run/host
  initScript = pkgs.writeText "${boxName}-init.sh" ''
    set -e
    if ! command -v google-chrome >/dev/null; then
      wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
      apt-get install -y /tmp/chrome.deb
      rm -f /tmp/chrome.deb
    fi

    # cshell_install.sh finds the user via `who`, but there's no utmp inside the container
    printf '#!/bin/sh\necho "${user} pts/0"\n' > /usr/local/bin/who
    chmod +x /usr/local/bin/who

    # snx runs `/sbin/modprobe tun` and gives up if it fails; the module is loaded on the host (boot.kernelModules)
    if [ ! -x /sbin/modprobe ]; then
      printf '#!/bin/sh\nexit 0\n' > /sbin/modprobe
      chmod +x /sbin/modprobe
    fi

    # cshell_install.sh imports its cert into Chrome's NSS db, which Chrome only creates lazily
    if [ ! -f "${boxHome}/.pki/nssdb/cert9.db" ]; then
      mkdir -p "${boxHome}/.pki/nssdb"
      certutil -N -d "sql:${boxHome}/.pki/nssdb" --empty-password
      chown -R "${user}:" "${boxHome}/.pki"
    fi
  '';

  # snx can't touch the host resolv.conf from inside the box, so the host follows tunsnx via udev.
  # DNS_SERVERS as pushed by the gateway (see "Primary/Secondary DNS IP" in /var/log/cshell/cshell.elg).
  # Exclusive (-x) because the gateway sends no DNS suffix for split DNS; the VPN DNS also resolves public names.
  resolvconf = "${config.networking.resolvconf.package}/bin/resolvconf";
  dnsUp = pkgs.writeShellScript "snx-dns-up" ''
    set -eu
    . ${envFile}
    for ns in $DNS_SERVERS; do
      printf 'nameserver %s\n' "$ns"
    done | ${resolvconf} -x -a tunsnx
  '';
  dnsDown = pkgs.writeShellScript "snx-dns-down" ''
    ${resolvconf} -f -d tunsnx
  '';

  manifest =pkgs.writeText "${boxName}.ini" ''
    [${boxName}]
    image=docker.io/library/ubuntu:22.04
    root=true
    init=false
    home=${boxHome}
    pre_init_hooks="dpkg --add-architecture i386"
    additional_packages="libnss3-tools openssl xterm default-jre wget ca-certificates net-tools"
    additional_packages="libpam0g:i386 libx11-6:i386 libstdc++6:i386 libstdc++5:i386"
    init_hooks="sh /run/host${initScript}"
  '';

  snx-box-create = pkgs.writeShellApplication {
    name = "snx-box-create";
    runtimeInputs = [ pkgs.distrobox ];
    text = ''
      distrobox assemble create --file /etc/distrobox/${boxName}.ini "$@"
    '';
  };

  # cshell is normally started via XDG autostart, which doesn't happen inside the box
  snx-vpn = pkgs.writeShellApplication {
    name = "snx-vpn";
    runtimeInputs = [ pkgs.distrobox ];
    text = ''
      if [ ! -r ${envFile} ]; then
        echo "snx-vpn: ${envFile} is missing, it needs PORTAL=<url> and DNS_SERVERS=\"<ip> ...\"" >&2
        exit 1
      fi
      # shellcheck source=/dev/null
      . ${envFile}
      # shellcheck disable=SC2016 # $1 is expanded by the inner sh
      distrobox enter --root ${boxName} -- sh -c \
        '[ -x /usr/bin/cshell/launcher ] && /usr/bin/cshell/launcher; google-chrome "$1"' sh "$PORTAL"
    '';
  };
in
{
  options.my.snx-vpn = {
    enable = lib.mkEnableOption "Check Point SNX VPN in an Ubuntu distrobox";
  };
  config = lib.mkIf config.my.snx-vpn.enable {
    assertions = [{
      assertion = config.my.container.enable;
      message = "my.snx-vpn requires my.container.enable (podman + distrobox)";
    }];

    boot.kernelModules = [ "tun" ];

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="tunsnx", RUN+="${dnsUp}"
      ACTION=="remove", SUBSYSTEM=="net", KERNEL=="tunsnx", RUN+="${dnsDown}"
    '';

    environment.etc."distrobox/${boxName}.ini".source = manifest;

    environment.systemPackages = [ snx-box-create snx-vpn ];
  };
}
