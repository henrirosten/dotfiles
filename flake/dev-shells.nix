{
  forAllSystems,
  mkPkgs,
  checks,
}:
forAllSystems (system: {
  default = (mkPkgs system).mkShell {
    inherit (checks.${system}.pre-commit-check) shellHook;
    buildInputs = checks.${system}.pre-commit-check.enabledPackages;
  };
})
