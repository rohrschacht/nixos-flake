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

        random_background = {
          body = ''
            set PICDIR ~/misc/wallpapers
            set CURPIC (ls $PICDIR | egrep -i "(png|jpg|jpeg)\$" | shuf -n 1)
            gsettings set org.gnome.desktop.background picture-uri $PICDIR/$CURPIC
            gsettings set org.gnome.desktop.background picture-uri-dark $PICDIR/$CURPIC
          '';
        };

        fw_ausweisapp = {
          body =''
            sudo iptables -I nixos-fw 6 -p udp --dport 24727 -j nixos-fw-accept
          '';
        };

        inf = {
          body =''
            set subcmd $argv[1]
            set args $argv[2..-1]

            if test -z $subcmd
              echo "Please specify subcommand, either:"
              echo "sync"
              echo "backup"
              return 1
            end

            switch $subcmd
              case sync
                __inf_rclone_gdrive_sync $args
              case backup
                __inf_borg_backup $args
              case '*'
                echo "Unknown subcommand: $subcmd" >&2
                return 1
            end
          '';
        };

        __inf_rclone_gdrive_sync = {
          body = ''
            set local_dir "$HOME/Gdrive/Infinithings"
            set remote_dir "infinithings:/Infinithings"

            echo "$(date +'%Y/%m/%d %H:%M:%S') Sync started" >> "$HOME/.config/rclone/rclone.log"

            rclone bisync \
              "$remote_dir" "$local_dir" \
              --compare size,modtime,checksum \
              --modify-window 1s \
              --create-empty-src-dirs \
              --drive-acknowledge-abuse \
              --drive-skip-gdocs \
              --drive-skip-shortcuts \
              --drive-skip-dangling-shortcuts \
              --metadata \
              --progress \
              --verbose \
              --log-file "$HOME/.config/rclone/rclone.log" \
              --track-renames \
              --fix-case \
              --resilient \
              --recover \
              --max-lock 2m \
              --check-access

            sleep 1

            if test $status -eq 0
              echo "$(date +'%Y/%m/%d %H:%M:%S') Sync done" >> "$HOME/.config/rclone/rclone.log"
            else
              echo "$(date +'%Y/%m/%d %H:%M:%S') Sync failed" >> "$HOME/.config/rclone/rclone.log"
            end
          '';
        };
      };

      shellInit = ''
        set fish_greeting
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

        abbr --add lg 'lazygit'

        abbr --add up 'os switch -u'

        abbr --add y yy
      '';
    };

    # myHomeManager.impermanence.cache.directories = [
    #   ".local/share/fish"
    # ];
  };
}
