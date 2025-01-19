{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
  ];
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true; # %wheel can setup

  environment.systemPackages = [ pkgs.wpa_supplicant ];
  users.users.root.password = "installer";

  # Keep it simpler
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
  };
  boot.initrd.systemd.enable = lib.mkForce false;

  # Super useful for liveusb, e.g. allows setting up a system from flake inputs.
  nicdumz.embedFlake = true;
  snowfallorg.users.ndumazet.create = false;
}
