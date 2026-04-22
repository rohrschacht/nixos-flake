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
      kubernetes-helm
      kubernetes-helmPlugins.helm-diff
      helmfile
    ];
  };
}
