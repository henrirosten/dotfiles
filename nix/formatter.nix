{
  forAllSystems,
  mkPkgs,
  checks,
}:
forAllSystems (
  system:
  let
    inherit (checks.${system}.pre-commit-check.config) package configFile;
    pkgs = mkPkgs system;
  in
  pkgs.writeShellScriptBin "pre-commit-run" ''
    ${pkgs.lib.getExe package} run --all-files --config ${configFile}
  ''
)
