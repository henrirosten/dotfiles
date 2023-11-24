{
  inputs = {
    
    # Nixpkgs
    # unstable:
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # release:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

    # Home manager
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      # HM version must match the nixpkgs.url version above (release, unstable)
      # unstable:
      # url = "github:nix-community/home-manager";
      # release:
      url = "github:nix-community/home-manager/release-23.05";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: 

  let
    inherit (self) outputs;
    users = {
      me = {
        # TODO: replace with your info
        name = "Henri Rosten";
        username = "hrosten";
        homeDirectory = "/home/hrosten";
        email = "henri.rosten@unikie.com";
      };
    };
  in {
    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager switch --flake .#hrosten'
    homeConfigurations = {
      # Home configuration for users.me
      "${users.me.username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
          user = users.me;
        };
        modules = [
          ./home-manager/home.nix
        ];
      };
    };
  };
}