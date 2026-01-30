{ lib, config, pkgs, ...}:

{
  options.my.git = {
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
      default = "220BE847F99B1B62!";
      description = "signing key identifier for git";
    };
  };

  config = {
    home.packages = with pkgs; [
      delta
    ];

    programs.git = {
      enable = true;

      settings = {
        user = {
          email = config.my.git.email;
          name = config.my.git.name;
        };

        core = {
          editor = "vim";
          pager = "delta";
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

        interactive = {
          diffFilter = "delta --color-only";
        };
        delta = {
          navigate = "true";
          side-by-side = "true";
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };

      signing.key = config.my.git.signingkey;
      signing.signByDefault = true;

      lfs.enable = true;
    };
  };
}
