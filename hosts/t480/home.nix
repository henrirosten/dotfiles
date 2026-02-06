{
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  home-manager.users."hrosten" =
    { ... }:
    {
      imports = with outputs.homeModules; [
        hm-hrosten
        gui-extras
      ];
    };
}
