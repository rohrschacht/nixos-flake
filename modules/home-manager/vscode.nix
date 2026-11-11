{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = {
    programs.vscode = {
      enable = true;
      # FIXME: vscode 1.144 moved its bundled ripgrep, nixpkgs' postPatch still
      # points at the old path (rm fails). Drop once nixpkgs is fixed.
      package =
        (pkgs.vscode.overrideAttrs (old: {
          postPatch =
            builtins.replaceStrings
              [ "resources/app/node_modules/@vscode/ripgrep/bin/rg" ]
              [ "resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg" ]
              old.postPatch;
        })).fhs;
    };
  };
}
