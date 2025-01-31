{ config, pkgs, ... }:
{
  services.openssh.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-curses;
  nicdumz.firewall.tcp = [ 22 ];

  # Default opens for all interfaces and it's not smart for the router.
  # TODO: sort of brittle condition, think about multiple interfaces etc.
  services.openssh.openFirewall = config.nicdumz.firewall.interface == "";
}
