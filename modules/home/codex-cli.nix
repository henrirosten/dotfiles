{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
