{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  # WirePlumber drop-in that hides every real webcam (and its libcamera twin)
  # from PipeWire, so PipeWire clients only see "OBS Cam". OBS itself reads
  # the webcam via V4L2 directly and is unaffected. Matching on device.name
  # because api.v4l2.cap.* isn't set yet when the rules run; real cameras are
  # "v4l2_device.pci-…", the loopback is "v4l2_device._sys_devices_virtual…".
  obscamOnlyConf = pkgs.writeText "50-hide-laptop-camera.conf" ''
    monitor.v4l2.rules = [
      {
        matches = [ { device.name = "~v4l2_device.pci-*" } ]
        actions = { update-props = { device.disabled = true } }
      }
    ]
    monitor.libcamera.rules = [
      {
        matches = [ { device.name = "~libcamera_device.*" } ]
        actions = { update-props = { device.disabled = true } }
      }
    ]
  '';
in
{
  config = {
    home.sessionPath = [
      "$HOME/.local/bin"
    ];

    home.packages = with pkgs; [
      fishPlugins.fzf-fish
    ];

    programs.fish = {
      enable = true;

      functions = {
        fish_prompt = {
          body = ''
            string join "" -- (set_color red) "[" (set_color yellow) $USER (set_color green) "@" (set_color blue) $hostname (set_color magenta) " " $(prompt_pwd) (set_color red) ']' (set_color normal) "\$ "
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
          body = ''
            sudo iptables -I nixos-fw 6 -p udp --dport 24727 -j nixos-fw-accept
          '';
        };

        # Firefox (with media.webrtc.camera.allow-pipewire) otherwise tries the
        # webcam OBS is holding and hangs ~9s per attempt before giving up.
        obscam = {
          body = ''
            set subcmd $argv[1]
            set conf $HOME/.config/wireplumber/wireplumber.conf.d/50-hide-laptop-camera.conf

            switch "$subcmd"
              case on
                mkdir -p (path dirname $conf)
                ln -sf ${obscamOnlyConf} $conf
                systemctl --user restart wireplumber
                # Restarting also makes WirePlumber re-probe OBS Cam, which it
                # only sees as a camera while the virtual camera is running.
                sleep 2
                if not wpctl status | string match -q '*OBS Cam (V4L2)*'
                  echo "OBS Cam not visible: start the virtual camera in OBS, then run 'obscam on' again" >&2
                  return 1
                end
              case off
                rm -f $conf
                systemctl --user restart wireplumber
                sleep 2
              case status
              case '*'
                echo "Please specify subcommand, either:"
                echo "on"
                echo "off"
                echo "status"
                return 1
            end

            if test -e $conf
              echo "obscam: on (webcams hidden, only OBS Cam)"
            else
              echo "obscam: off (all cameras visible)"
            end
            wpctl status | sed -n '/^Video/,/Streams/p' | sed -n '/Sources:/,/Filters:/{/Filters:/d;p}'
          '';
        };

        clidev = {
          body = ''
            set subcmd $argv[1]

            if test -z $subcmd
              echo "Please specify subcommand, either:"
              echo "flake"
              echo "clangd"
              return 1
            end

            switch $subcmd
              case flake
                set flakeTemplate $argv[2]
                if test -z $flakeTemplate
                  echo "Please specify flake template, either:"
                  echo "cpp-dev"
                  echo "go-dev"
                  echo "haskell-dev"
                  echo "javascript-dev"
                  echo "python-dev"
                  echo "rust-dev"
                  echo "scala-dev"
                  return 2
                end
                  
                switch $flakeTemplate
                  case cpp-dev go-dev haskell-dev javascript-dev python-dev rust-dev scala-dev
                    nix flake init --template "github:DeterminateSystems/zero-to-nix#$flakeTemplate"
                  case '*'
                    echo "$flakeTemplate not recognized"
                end

              case clangd
                mkdir -p build
                cmake -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -B build
                ln -s build/compile_commands.json .

              case '*'
                echo "Unknown subcommand: $subcmd" >&2
                return 1
            end
          '';
        };

        inf = {
          body = ''
            set subcmd $argv[1]
            set args $argv[2..-1]

            if test -z $subcmd
              echo "Please specify subcommand, either:"
              echo "sync"
              echo "backup"
              echo "work"
              return 1
            end

            switch $subcmd
              case sync
                __inf_rclone_gdrive_sync $args
              case backup
                __inf_borg_backup $args
              case work
                __inf_work $args
              case '*'
                echo "Unknown subcommand: $subcmd" >&2
                return 1
            end
          '';
        };

        __inf_work = {
          body = ''
            # New tabs inherit the focused pane's cwd, so all four land where
            # `inf work` was invoked. Commands are wrapped in interactive fish
            # because claude-inf is an alias (interactive-only), and `exec fish`
            # leaves a usable shell in the tab once the command exits.
            if set -q ZELLIJ
              zellij action rename-tab git
              zellij action new-tab --name claude -- fish -ic 'claude-inf; exec fish'
              zellij action new-tab --name nvim -- fish -ic 'nvim; exec fish'
              zellij action new-tab --name shell
              zellij action go-to-tab-name git
            else if set -q KITTY_WINDOW_ID
              kitten @ set-tab-title git
              kitten @ launch --type=tab --tab-title claude --cwd=current fish -ic 'claude-inf; exec fish' >/dev/null
              kitten @ launch --type=tab --tab-title nvim --cwd=current fish -ic 'nvim; exec fish' >/dev/null
              kitten @ launch --type=tab --tab-title shell --cwd=current >/dev/null
              kitten @ focus-tab --match 'title:^git$'
            else
              echo "inf work must be run inside zellij or kitty" >&2
              return 1
            end

            # Runs in this very pane, so quitting lazygit returns to the prompt.
            # `zellij run --in-place` would suspend the shell running this script.
            lazygit
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

      completions = {
        clidev = ''
          complete -c clidev -x -a "flake clangd"
        '';
        obscam = ''
          complete -c obscam -x -a "on off status"
        '';
      };

      shellInit = ''
        set fish_greeting
      '';

      shellAliases = {
        os = "nh os";
        clean = "nh clean";
        claude-inf = "CLAUDE_CONFIG_DIR=~/.claude-inf claude";
      };

      interactiveShellInit = ''
        if command -v eza >/dev/null 2>&1
            alias ls 'eza'
            alias ll 'eza --long --group --grid'
            alias la 'eza --all --long --group --grid'
            alias lsg 'eza --all --long --no-permissions --no-user --no-time --git --icons --tree --git-ignore --level=2'
        else
            alias ll 'ls -lh'
            alias la 'ls -lah'
        end

        if command -v starship >/dev/null 2>&1
            starship init fish | source
        end

        fzf_configure_bindings --directory=\ct --processes=\ck

        # kitten ssh ships terminfo + shell integration to the remote, so
        # `launch --cwd=current` (new pane/tab) opens on the remote host too
        if set -q KITTY_WINDOW_ID
            function ssh --wraps ssh --description 'kitten ssh'
                set -l extra
                # ncurses may ignore ~/.terminfo for root (--disable-root-environ,
                # e.g. openSUSE), so as root also install it system-wide. The
                # user comes from ~/.ssh/config, which kitten ssh's hostname
                # matching in ssh.conf never sees.
                if command ssh -G $argv 2>/dev/null | string match -q 'user root'
                    set extra --kitten "copy=--dest /etc/terminfo/x/xterm-kitty ${config.programs.kitty.package.terminfo}/share/terminfo/x/xterm-kitty"
                end
                kitten ssh $extra $argv
            end
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

        abbr --add sw 'os switch'
        abbr --add up 'os boot -u'

        abbr --add rls rclone tree --size --human-readable --level=1
      '';
    };

    # myHomeManager.impermanence.cache.directories = [
    #   ".local/share/fish"
    # ];

    programs.fzf = {
      enable = true;
      enableFishIntegration = false;
    };
  };

}
