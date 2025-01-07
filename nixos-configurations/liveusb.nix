{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
  ];
  networking.hostName = "liveusb";
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Super useful for liveusb, e.g. allows setting up a system from flake inputs.
  nicdumz.embedFlake = true;
}
