{
  inputs,
  outputs,
  stateVersion,
  ...
}:
let
  hrosten = import ../../users/hrosten/hrosten.nix;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
  ]
  ++ (with outputs.nixosModules; [
    common-nix
    host-common
    ssh
    hrosten.nixosModule
  ]);

  networking.hostName = "generic";

  services.getty.autologinUser = hrosten.user.username;
  programs.dconf.enable = true;
  security.sudo.wheelNeedsPassword = false;
  system.autoUpgrade.dates = "weekly";

  home-manager.extraSpecialArgs = {
    inherit
      inputs
      outputs
      stateVersion
      ;
  };

  home-manager.users.${hrosten.user.username} =
    { ... }:
    {
      imports = [
        ../../users/hrosten/home.nix
        outputs.homeModules.gui-extras
        (
          { lib, ... }:
          {
            # Keep VM Codex state local/writable.
            home.activation.ensureWritableCodexHome = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
              if [ -L "$HOME/.codex" ]; then
                rm -f "$HOME/.codex"
              fi
              if [ -L "$HOME/.codex/auth.json" ]; then
                rm -f "$HOME/.codex/auth.json"
              fi
              mkdir -p "$HOME/.codex"
              chmod 700 "$HOME/.codex"
            '';
          }
        )
      ];
    };
}
