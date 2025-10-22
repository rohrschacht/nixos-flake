{ lib, config, pkgs, ... }:

{
  config = {
    home.packages = with pkgs; [
      ansible
      terraform
      aha
      wkhtmltopdf
    ];
  };
}
