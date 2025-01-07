{ lib, config, pkgs, ...}:

{
  options.my-git = {
    email = lib.mkOption {
      type = lib.types.str;
      default = "tobias@rohrschacht.de";
      description = "user email for git";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "Rohrschacht";
      description = "user name for git";
    };
    signingkey = lib.mkOption {
      type = lib.types.str;
      default = "D99301AD0515015F!";
      description = "signing key identifier for git";
    };
  };

  config = {
    programs.git = {
      enable = true;

      userEmail = config.my-git.email;
      userName = config.my-git.name;

      signing.key = config.my-git.signingkey;
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
