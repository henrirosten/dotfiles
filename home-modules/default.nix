{
  bash = import ./bash.nix;
  codium = import ./codium.nix;
  common-home = import ./common-home.nix;
  extras = import ./extras.nix;
  git = import ./git.nix;
  ssh-conf = import ./ssh-conf.nix;
  starship = import ./starship.nix;
  vim = import ./vim.nix;
  vscode = import ./vscode.nix;
  zsh = import ./zsh.nix;
}
