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
  };

  outputs =
    inputs@{ self, ... }:
    let
      inherit (self) outputs;

      specialArgs = {
        inherit inputs outputs;
        user = {
          name = "Henri Rosten";
          username = "hrosten";
          homedir = "/home/hrosten";
          email = "henri.rosten@unikie.com";
          keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFuB+uEjhoSdakwiKLD3TbNpbjnlXerEfZQbtRgvdSz"
          ];
        };
      };
    in
    {
      nixosModules = import ./nix-modules;
      homeManagerModules = import ./home-modules;

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#hrosten'
      homeConfigurations = rec {
        "hrosten" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
            inherit (specialArgs) user;
          };
          modules = [
            outputs.homeManagerModules.bash
            outputs.homeManagerModules.common-home
            outputs.homeManagerModules.extras
            outputs.homeManagerModules.git
            outputs.homeManagerModules.ssh-conf
            outputs.homeManagerModules.starship
            outputs.homeManagerModules.vim
            outputs.homeManagerModules.zsh
            inputs.nix-index-database.homeModules.nix-index
            {
              home.username = specialArgs.user.username;
            }
          ];
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

      formatter.x86_64-linux =
        let
          inherit (outputs.checks.x86_64-linux.pre-commit-check.config) package configFile;
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.writeShellScriptBin "pre-commit-run" ''
          ${pkgs.lib.getExe package} run --all-files --config ${configFile}
        '';

      checks.x86_64-linux = {
        pre-commit-check = inputs.git-hooks-nix.lib.x86_64-linux.run {
          src = self.outPath;
          # default_stages = ["pre-commit" "pre-push"];
          hooks = {
            # lint commit messages
            gitlint.enable = true;
            # fix end-of-files
            end-of-file-fixer.enable = true;
            # spell check
            typos.enable = true;
            # nix formatter (rfc-style)
            nixfmt-rfc-style.enable = true;
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
      };

      devShells.x86_64-linux = {
        default = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
          inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
          buildInputs = self.checks.x86_64-linux.pre-commit-check.enabledPackages;
        };
      };
    };
}
