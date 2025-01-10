# Those are settings which mostly only make sense in the context of running
# NixOS as part of a Guest VM.
{
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  fileSystems."/media/host" = {
    device = "shared0";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "posixacl"
      "cache=mmap"
    ];
  };
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true; # enable copy and paste between host and guest
}
