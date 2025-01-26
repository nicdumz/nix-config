{
  namespace,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./windows-dual.nix
  ];

  boot.kernelModules = [ "kvm-intel" ]; # Will run VMs.

  disko.devices = lib.${namespace}.mkEncryptedDiskLayout {
    swapsize = 32;
    device = "/dev/disk/by-id/WD_BLACK_SN770_2TB_230502467307";
  };

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
    tailscale.enable = true;
    scaling = {
      defaultFontSize = 18;
      factor = 1.25;
    };
  };
  snowfallorg.users.giulia.create = true;

  # `networkctl` is nice, afterall.
  systemd.network = {
    enable = true;

    wait-online = {
      extraArgs = [
        "--ipv4"
        "--ipv6"
        "--interface=enp3s0"
      ];
      timeout = 20; # seconds
    };
  };
}
