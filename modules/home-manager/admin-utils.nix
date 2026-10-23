{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = {
    home.packages = with pkgs; [
      ansible
      terraform
      aha
      wkhtmltopdf
      kubectl
      kind
      k3d
      kubernetes-helm
      kubernetes-helmPlugins.helm-diff
      helmfile
      iperf
      cdrkit
    ];
  };
}
