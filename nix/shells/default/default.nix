{
  mkShell,
  inputs,
  system,
  pkgs,
  ...
}:
# The 'default' devShell can be invoked manually with `nix develop` from the flake directory, and
# direnv integration means that cd'ing into this dev directory (after allow-listing)
# automatically loads the relevant development shell + helpful tools.
mkShell {
  # Note: this refers to our checks/git-hooks module.
  inherit (inputs.self.checks.${system}.git-hooks) shellHook;

  packages = [
    inputs.agenix-rekey.packages.${system}.default
    # Note: pgs.colmena below would be too old
    inputs.colmena.defaultPackage.${system}
  ];

  buildInputs = [
    pkgs.age-plugin-fido2-hmac
  ];
}
