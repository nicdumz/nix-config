{
  inputs,
  pkgs,
  system,
  ...
}:
inputs.git-hooks-nix.lib.${pkgs.system}.run {
  src = inputs.self.outPath;
  hooks.treefmt = {
    enable = true;
    packageOverrides.treefmt = inputs.self.formatter.${system};
  };
}
