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
let
  # Note: this refers to our checks/git-hooks module.
  check = inputs.self.checks.${system}.git-hooks;
in
mkShell {
  inherit (check) shellHook;

  packages = [
    inputs.agenix-rekey.packages.${system}.default
    # Note: pgs.colmena below would be too old
    inputs.colmena.defaultPackage.${system}
    pkgs.age-plugin-fido2-hmac
  ];
  buildInputs = check.enabledPackages;
}
