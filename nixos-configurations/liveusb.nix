{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
  ];
  networking.hostName = "liveusb";
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true; # %wheel can setup

  environment.systemPackages = [ pkgs.wpa_supplicant ];

  # Super useful for liveusb, e.g. allows setting up a system from flake inputs.
  nicdumz.embedFlake = true;
}
