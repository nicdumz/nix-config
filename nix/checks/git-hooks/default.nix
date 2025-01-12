{
  inputs,
  system,
  ...
}:
inputs.git-hooks-nix.lib.${system}.run {
  src = inputs.self.outPath;
  hooks = {
    actionlint.enable = true;
    detect-private-keys.enable = true;
    end-of-file-fixer.enable = true;
    flake-checker.enable = true;
    # no commit to main branch, force use of PRs.
    no-commit-to-branch.enable = true;
    statix.enable = true;
    treefmt = {
      enable = true;
      packageOverrides.treefmt = inputs.self.formatter.${system};
    };
  };
}
