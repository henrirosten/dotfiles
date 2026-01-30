_: {
  imports = [ ./shell-common.nix ];

  programs.bash = {
    enable = true;
    historyFileSize = 1000000;
    historySize = 1000000;
    shellOptions = [
      "histappend"
      "checkwinsize"
    ];
    bashrcExtra = ''
      # Source shared shell functions
      [ -f "$HOME/.local/share/shell-functions.sh" ] && . "$HOME/.local/share/shell-functions.sh"

      export HISTCONTROL=ignoreboth
      export HISTFILE="$HOME"/.bash_eternal_history
      PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
      #PROMPT_COLOR="1;90m"
      PROMPT_COLOR="1;32m"
      export PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "

      # Bash-specific: minimize history file (uses bash history builtin)
      own-minhist () {
          cp ~/.bash_eternal_history ~/.bash_eternal_history.old
          history -w /dev/stdout | nl | sort -k2 -k 1,1nr | uniq -f1 | sort -n | cut -f2 > ~/.bash_eternal_history
          echo "Wrote ~/.bash_eternal_history. Old history in ~/.bash_eternal_history.old"
      }
    '';
    initExtra = ''
      if [ -z ''${LANG+x} ]; then LANG=en_US.utf8; fi
    '';
  };
}
