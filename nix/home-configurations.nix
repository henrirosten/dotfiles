{
  inputs,
  systems,
  defaultSystem,
  mkPkgs,
  specialArgs,
}:
(builtins.listToAttrs (
  map (system: {
    name = "hrosten-${system}";
    value = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs system;
      extraSpecialArgs = specialArgs;
      modules = [ ../users/hrosten/home.nix ];
    };
  }) systems
))
// {
  "hrosten" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = mkPkgs defaultSystem;
    extraSpecialArgs = specialArgs;
    modules = [ ../users/hrosten/home.nix ];
  };
}
