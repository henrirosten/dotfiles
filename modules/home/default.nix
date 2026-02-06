{
  bash = import ./bash.nix;
  gui-extras = import ./gui-extras.nix;
  git = import ./git.nix;
  hm-hrosten = import ./hm-hrosten.nix;
  shell-common = import ./shell-common.nix;
  ssh-conf = import ./ssh-conf.nix;
  starship = import ./starship.nix;
  vim = import ./vim.nix;
  vscode = import ./vscode.nix;
  zsh = import ./zsh.nix;
}
