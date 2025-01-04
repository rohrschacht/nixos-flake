{ lib, config, pkgs, ...}:

{
  config = {
    programs.fish = {
      enable = true;

      functions = {
        fish_prompt = {
          body = ''
            string join "" -- (set_color red) "[" (set_color yellow) $USER (set_color green) "@" (set_color blue) $hostname (set_color magenta) " " $(prompt_pwd) (set_color red) ']' (set_color normal) "\$ "
          '';
        };

        lfcd = {
          body = ''
            cd "$(command lf -print-last-dir $argv)"
          '';
        };

        hst = {
          body = ''
            history | uniq | ${pkgs.fzf}/bin/fzf | ${pkgs.wl-clipboard}/bin/wl-copy -n
          '';
        };
      };

      shellInit = ''
        set fish_greeting

        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
      '';

      shellAliases = {
        lf = "lfcd";
        os = "nh os";
        clean = "nh clean";
      };

      interactiveShellInit = ''
        if command -v eza >/dev/null 2>&1
            alias ls 'eza'
            alias ll 'eza -lgG'
            alias la 'eza -lgaG'
        else
            alias ll 'ls -lh'
            alias la 'ls -lah'
        end
 
        if command -v starship >/dev/null 2>&1
            starship init fish | source
        end
 
        abbr --add g 'git'
        abbr --add ga 'git add'
        abbr --add gaa 'git add --all'
        abbr --add gb 'git branch'
        abbr --add gbD 'git branch --delete --force'
        abbr --add gba 'git branch --all'
        abbr --add gbd 'git branch --delete'
        abbr --add gbgd 'LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk \'{print $1}\' | xargs git branch -d'
        abbr --add gbgD 'LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk \'{print $1}\' | xargs git branch -D'
        abbr --add gbr 'git branch --remote'
        abbr --add gc 'git commit --verbose'
        abbr --add gcb 'git checkout -b'
        abbr --add gcl 'git clone --recurse-submodules'
        abbr --add gco 'git checkout'
        abbr --add gd 'git diff'
        abbr --add gds 'git diff --staged'
        abbr --add gf 'git fetch'
        abbr --add gfa 'git fetch --all --prune --jobs=10'
        abbr --add gl 'git pull'
        abbr --add glog 'git log --oneline --decorate --graph'
        abbr --add gloga 'git log --oneline --decorate --graph --all'
        abbr --add glol 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
        abbr --add glola 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
        abbr --add gm 'git merge'
        abbr --add gp 'git push'
        abbr --add gr 'git remote'
        abbr --add gra 'git remote add'
        abbr --add grmv 'git remote rename'
        abbr --add grrm 'git remote remove'
        abbr --add gst 'git status'
        abbr --add gsta 'git stash push'
        abbr --add gstaa 'git stash apply'
        abbr --add gstc 'git stash clear'
        abbr --add gstd 'git stash drop'
        abbr --add gstl 'git stash list'
        abbr --add gstp 'git stash pop'
        abbr --add gwipe 'git reset --hard && git clean --force -df'

        abbr --add up 'os switch -u'
      '';
    };

    # myHomeManager.impermanence.cache.directories = [
    #   ".local/share/fish"
    # ];
  };
}
