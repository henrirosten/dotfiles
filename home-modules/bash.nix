_: {
  programs.bash = {
    enable = true;
    historyFileSize = 1000000;
    historySize = 1000000;
    shellOptions = ["histappend" "checkwinsize"];
    bashrcExtra = ''
      export EDITOR=vim
      export HISTCONTROL=ignoreboth
      export HISTFILE="$HOME"/.bash_eternal_history
      PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
      #PROMPT_COLOR="1;90m"
      PROMPT_COLOR="1;32m"
      export PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
      export XDG_DATA_DIRS=$HOME/.nix-profile/share:$XDG_DATA_DIRS
      # Disable ctrl-s (pause terminal output)
      stty -ixon

      own-minhist () {
          cp ~/.bash_eternal_history ~/.bash_eternal_history.old
          history -w /dev/stdout | nl | sort -k2 -k 1,1nr | uniq -f1 | sort -n | cut -f2 > ~/.bash_eternal_history
          echo "Wrote ~/.bash_eternal_history. Old history in ~/.bash_eternal_history.old"
      }

      own-allfiles () {
          sudo find / -type f ! -path "/dev/*" ! -path "/sys/*" ! -path "/proc/*" ! -path "/run/*" > ~/allfiles.txt
          echo "Wrote ~/allfiles.txt"
      }

      own-find-largest () {
          if [ -z "$1" ]; then
              findpath="$PWD"
          else
              findpath="$1"
          fi
          if [ -z "$2" ]; then
              n="20"
          else
              n="$2"
          fi
          find "$findpath" -type f -exec du -h {} + | sort -r -h | head -n "$n"
      }

      own-find-links () {
          if [ -z "$1" ]; then
              findpath="$PWD"
          else
              findpath="$1"
          fi
          find "$findpath" -type l -exec echo -n "{} -> " \; -exec readlink -f {} \;
      }

      own-nix-store-symlinks () {
          # Find all symlinks in HOME that point somewhere in /nix/store.
          # grep -v removes (home-manager managed) dotfiles from the output results.
          own-find-links "$HOME" | grep "/nix/store" | grep -vP "$HOME\/\."
      }

      own-nix-info () {
          echo "nix-info:"
          nix-info -m
          echo "nix-channel:"
          echo " - root: $(sudo "$(which nix-channel)" --list)"
          echo " - $USER: $(nix-channel --list)"
          echo ""
          echo "nixpkgs:"
          echo " - nixpkgs version: $(nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version')"
      }

      own-nix-clean () {
          nix-collect-garbage
          # notify if it seems some symlinks prevent full cleanup
          if own-nix-store-symlinks > /dev/null 2>&1; then
              echo ""
              echo "Note: following symlinks in '$HOME' prevent nix-collect-garbage to fully clean the store:"
              own-nix-store-symlinks
          fi
          echo ""
          echo "Consider manually removing old profiles from '/nix/var/nix/profiles':"
          find /nix/var/nix/profiles/
          echo ""
          echo "Consider manually removing logs from '/nix/var/log/nix/drvs/'"
          own-find-largest /nix/var/log/nix/drvs/ 10
      }
    '';
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };
    initExtra = ''
      if [ -z ''${LANG+x} ]; then LANG=en_US.utf8; fi
    '';
  };
}
