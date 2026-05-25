{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git-crypt
    glow
    nixd
    nixfmt-rfc-style
    nixpkgs-review
  ];
}
