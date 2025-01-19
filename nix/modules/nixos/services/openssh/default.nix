{ pkgs, ... }:
{
  services.openssh.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-curses;
}
