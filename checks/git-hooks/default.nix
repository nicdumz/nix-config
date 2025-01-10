{
  inputs,
  pkgs,
  lib,
  system,
  ...
}:
inputs.git-hooks-nix.lib.${pkgs.system}.run {
  src = lib.snowfall.fs.get-file "/";
  hooks.treefmt = {
    enable = true;
    packageOverrides.treefmt = inputs.self.formatter.${system};
  };
}
