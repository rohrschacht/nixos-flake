{ lib, config, pkgs, ... }:

{
  config = {
    home.packages = with pkgs; [
      ansible
      ansible-lint
      terraform
      aha
      wkhtmltopdf
    ];
  };
}
