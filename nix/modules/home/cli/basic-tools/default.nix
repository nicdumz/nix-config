{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git-crypt
    glow
    nixd
    nixfmt
    nixpkgs-review
  ];
}
