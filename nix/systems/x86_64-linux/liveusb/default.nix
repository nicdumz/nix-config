{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  # Explicit root password; cancel the upstream installer profile's
  # passwordless `initialHashedPassword = "";` default to avoid ambiguity
  # between the two password mechanisms.
  users.users.root.initialHashedPassword = lib.mkForce null;
  users.users.root.password = "installer";

  # hardware.enableAllHardware (from the upstream installer profile) pulls in
  # zfs support, which otherwise warns about the insecure (pre-26.11) default.
  boot.zfs.forceImportRoot = false;

  # Keep it simpler
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
  };

  snowfallorg.users.ndumazet.create = false;

  # Installer is headless.
  nicdumz.device.type = "server";
}
