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
  # Note: this is cool. Would be a nativeBuildInput
  # pkgs.writeTextFile
  # {
  #   name = "mkModuleHelpers.completions"; # just a name
  #   destination = "/share/fish/vendor_completions.d/${namespace}-helpers.fish";
  #   text = ''
  #     set -l commands home nixos
  #     complete -c futurecmd -f # no file completions
  #     complete -c futurecmd -n "not __fish_seen_subcommand_from $commands" -ra 'home' 'nixos'
  #     complete -c futurecmd -ra 'home nixos'
  #   '';
  # };

  packages = [
    pkgs.jq
    pkgs.sops
    pkgs.ssh-to-age
    # Note: pgs.colmena below would be too old
    inputs.colmena.defaultPackage.${system}
    pkgs.age-plugin-fido2-hmac
  ];
  buildInputs = check.enabledPackages;
}
