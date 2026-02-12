{ inputs, self }:
system:
inputs.git-hooks-nix.lib.${system}.run {
  src = self.outPath;
  # default_stages = ["pre-commit" "pre-push"];
  hooks = {
    # lint commit messages
    gitlint.enable = true;
    # fix end-of-files
    end-of-file-fixer.enable = true;
    # spell check
    typos.enable = true;
    # nix formatter
    nixfmt.enable = true;
    # removes dead nix code
    deadnix.enable = true;
    # prevents use of nix anti-patterns
    statix = {
      enable = true;
      args = [
        "fix"
      ];
    };
    # bash linter
    shellcheck.enable = true;
    # bash formatter
    shfmt = {
      enable = true;
      args = [
        "--indent"
        "2"
      ];
    };
  };
}
