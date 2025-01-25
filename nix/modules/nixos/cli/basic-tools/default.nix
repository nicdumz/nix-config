{ pkgs, ... }:
{
  security.sudo.extraConfig = "Defaults insults,timestamp_timeout=30";

  environment.systemPackages = with pkgs; [
    colordiff
    git
    htop
    killall
    kitty.terminfo
    tcpdump
    unzip
    wget
  ];
}
