{ pkgs, ... }:
{
  home.packages = with pkgs; [
    colordiff
    dig
    ethtool
    git
    git-crypt
    glow
    htop
    killall
    kitty.terminfo
    nixd
    nixfmt-rfc-style
    nixpkgs-review
    tcpdump
    unzip
    wget
  ];
}
