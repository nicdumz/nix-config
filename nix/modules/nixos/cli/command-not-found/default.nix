{ inputs, ... }:
{
  imports = [
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
  ];
  programs.command-not-found.enable = true; # somehow disabled in cd-minimal
}
