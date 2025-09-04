{
  common-nix = import ./common-nix.nix;
  gui = import ./gui.nix;
  laptop = import ./laptop.nix;
  ssh-access = import ./ssh-access.nix;
  remotebuild = import ./remotebuild.nix;
}
