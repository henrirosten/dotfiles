{ inputs, specialArgs }:
{
  x1 = inputs.nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    modules = [ ../hosts/x1/configuration.nix ];
  };

  t480 = inputs.nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    modules = [ ../hosts/t480/configuration.nix ];
  };
}
