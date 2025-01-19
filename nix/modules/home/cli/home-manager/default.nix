{ inputs, ... }:
{
  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  # For nixd
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
}
