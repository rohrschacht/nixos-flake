{ lib, config, pkgs, ...}:

{
  config = {
    programs.git = {
      enable = true;

      userEmail = "tobias@rohrschacht.de";
      userName = "Rohrschacht";

      signing.key = "D99301AD0515015F!";
      signing.signByDefault = true;

      lfs.enable = true;

      extraConfig = {
        core = {
          editor = "vim";
        };
        pull = {
          ff = "only";
        };
        init = {
          defaultBranch = "main";
        };
        push = {
          default = "current";
        };
      };
    };
  };
}
