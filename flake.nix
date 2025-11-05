{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    bombon.url = "github:nikstur/bombon";
  };

  outputs = inputs @ {self, ...}: let
    inherit (self) outputs;

    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

    compare-runtime-meta = pkgs.writeShellScriptBin "run" ''
      set -u
      ${pkgs.lib.getExe pkgs.nix} build ${self.outPath}#sbom-bombon-x1-runtime --out-link tmp_bombon_runtime_out
      echo "\"name\",\"version\",\"meta_description\"" >tmp_bombon_runtime.csv
      ${pkgs.lib.getExe pkgs.jq} --raw-output '.components[] | [.name, .version, .description] | @csv' tmp_bombon_runtime_out >>tmp_bombon_runtime.csv
      ${pkgs.csvkit}/bin/csvsql --query "select distinct name,version,meta_description from tmp_bombon_runtime where meta_description is not null order by name,version" tmp_bombon_runtime.csv >tmp_bombon_runtime_meta.csv
      bombon_pkgs=$(${pkgs.csvkit}/bin/csvstat --count tmp_bombon_runtime.csv)
      bombon_meta_pkgs=$(${pkgs.csvkit}/bin/csvstat --count tmp_bombon_runtime_meta.csv)

      ${pkgs.lib.getExe pkgs.sbomnix} ${self.outPath}#nixosConfigurations.x1.config.system.build.toplevel --csv tmp_sbomnix_runtime.csv
      ${pkgs.csvkit}/bin/csvsql --query "select distinct pname_meta,version_meta,meta_description from tmp_sbomnix_runtime where meta_description is not null order by pname_meta,version_meta" tmp_sbomnix_runtime.csv >tmp_sbomnix_runtime_meta.csv
      sbomnix_pkgs=$(${pkgs.csvkit}/bin/csvstat --count tmp_sbomnix_runtime.csv)
      sbomnix_meta_pkgs=$(${pkgs.csvkit}/bin/csvstat --count tmp_sbomnix_runtime_meta.csv)

      ${pkgs.lib.getExe pkgs.nix} run github:tiiuae/ci-public/317d464?dir=csvdiff#csvdiff -- --cols=meta_description --ignoredups tmp_sbomnix_runtime.csv tmp_bombon_runtime.csv --out tmp_csvdiff.csv

      echo ""
      echo "[+] sbomnix missing nix meta from following packages: "
      ${pkgs.csvkit}/bin/csvsql --query "select distinct name,diff from tmp_csvdiff where diff like 'right_only'" tmp_csvdiff.csv | cut -d"," -f1 | tail -n +2

      echo ""
      echo "[+] bombon missing nix meta from following packages: "
      ${pkgs.csvkit}/bin/csvsql --query "select distinct name,diff from tmp_csvdiff where diff like 'left_only'" tmp_csvdiff.csv | cut -d"," -f1 | tail -n +2

      echo ""
      echo "[+] bombon:  packages with nix meta: $bombon_meta_pkgs (out of $bombon_pkgs packages)"
      echo "[+] sbomnix: packages with nix meta: $sbomnix_meta_pkgs (out of $sbomnix_pkgs packages)"
    '';

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
  in rec {
    nixosModules = import ./nix-modules;
    homeManagerModules = import ./home-modules;

    apps.x86_64-linux = {
      run-compare-runtime-meta = {
        type = "app";
        program = "${compare-runtime-meta}/bin/run";
      };
    };

    packages.x86_64-linux = {
      sbom-bombon-x1-runtime = inputs.bombon.lib.x86_64-linux.buildBom nixosConfigurations.x1.config.system.build.toplevel {
        includeBuildtimeDependencies = false;
      };
    };

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
        modules = [./hosts/x1/configuration.nix];
      };
      t480 = inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [./hosts/t480/configuration.nix];
      };
    };

    formatter.x86_64-linux =
      inputs.treefmt-nix.lib.mkWrapper
      inputs.nixpkgs.legacyPackages.x86_64-linux
      {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # nix formatter https://github.com/kamadorueda/alejandra
          deadnix.enable = true; # removes dead nix code https://github.com/astro/deadnix
          statix.enable = true; # prevents use of nix anti-patterns https://github.com/nerdypepper/statix
          shellcheck.enable = true; # lints shell scripts https://github.com/koalaman/shellcheck
        };
      };

    checks.x86_64-linux = {
      pre-commit-check = inputs.git-hooks-nix.lib.x86_64-linux.run {
        src = self.outPath;
        # default_stages = ["pre-commit" "pre-push"];
        hooks = {
          treefmt = {
            package = outputs.formatter.x86_64-linux;
            enable = true;
          };
          end-of-file-fixer.enable = true;
          typos.enable = true;
          gitlint.enable = true;
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
