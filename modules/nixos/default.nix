{
  common-nix = import ./common-nix.nix;
  gui = import ./gui.nix;
  host-common = import ./host-common.nix;
  laptop = import ./laptop.nix;
  ssh-access = import ./ssh-access.nix;
  remotebuild = import ./remotebuild.nix;
}
