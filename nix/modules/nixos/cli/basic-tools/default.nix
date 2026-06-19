{ pkgs, ... }:
{
  security.sudo.extraConfig = "Defaults insults,timestamp_timeout=30";

  # Stuff that root user and others may need
  environment.systemPackages = with pkgs; [
    arp-scan
    colordiff
    dig
    ethtool
    git
    htop
    killall
    kitty.terminfo
    tcpdump
    unzip
    wget
  ];
}
