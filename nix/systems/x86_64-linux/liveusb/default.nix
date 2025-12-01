{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  users.users.root.password = "installer";

  # Keep it simpler
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
  };
  boot.initrd.systemd.enable = lib.mkForce false;

  snowfallorg.users.ndumazet.create = false;
}
