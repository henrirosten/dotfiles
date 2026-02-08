{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      inherit (self) outputs;
      stateVersion = "23.11";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      defaultSystem = "x86_64-linux";
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
      mkPkgs = system: inputs.nixpkgs.legacyPackages.${system};

      specialArgs = {
        inherit
          inputs
          outputs
          stateVersion
          ;
      };

      mkPreCommitCheck =
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
        };
    in
    {
      nixosModules = import ./modules/nixos;
      homeModules = import ./modules/home;

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#hrosten'
      # Cross-system entries are also exported as:
      # - hrosten-x86_64-linux
      # - hrosten-aarch64-linux
      homeConfigurations =
        (builtins.listToAttrs (
          map (system: {
            name = "hrosten-${system}";
            value = inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = mkPkgs system;
              extraSpecialArgs = specialArgs;
              modules = [ ./users/hrosten/home.nix ];
            };
          }) systems
        ))
        // {
          "hrosten" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = mkPkgs defaultSystem;
            extraSpecialArgs = specialArgs;
            modules = [ ./users/hrosten/home.nix ];
          };
        };

      nixosConfigurations = {
        x1 = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [ ./hosts/x1/configuration.nix ];
        };
        t480 = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [ ./hosts/t480/configuration.nix ];
        };
      };

      formatter = forAllSystems (
        system:
        let
          inherit (outputs.checks.${system}.pre-commit-check.config) package configFile;
          pkgs = mkPkgs system;
        in
        pkgs.writeShellScriptBin "pre-commit-run" ''
          ${pkgs.lib.getExe package} run --all-files --config ${configFile}
        ''
      );

      checks = forAllSystems (system: {
        pre-commit-check = mkPreCommitCheck system;
      });

      devShells = forAllSystems (system: {
        default = (mkPkgs system).mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });
    };
}
