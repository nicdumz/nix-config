{
  inputs,
  pkgs,
  ...
}:
inputs.git-hooks-nix.lib.${pkgs.stdenv.hostPlatform.system}.run {
  src = inputs.self.outPath;
  hooks = {
    actionlint.enable = true;
    detect-private-keys.enable = true;
    end-of-file-fixer.enable = true;
    flake-checker.enable = true;
    flake-checker.package =
      inputs.flake-checker.packages.${pkgs.stdenv.hostPlatform.system}.flake-checker;
    # no commit to main branch, force use of PRs.
    no-commit-to-branch.enable = true;
    statix.enable = true;
    treefmt = {
      enable = true;
      packageOverrides.treefmt = inputs.self.formatter.${pkgs.stdenv.hostPlatform.system};
    };
  };
}
