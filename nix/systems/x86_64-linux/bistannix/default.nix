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

  networking.networkmanager.enable = false;
  networking.useDHCP = false;
  # `networkctl` is nice, afterall.
  systemd.network = {
    enable = true;

    links."10-lan" = {
      matchConfig = {
        Type = "ether";
        MACAddress = "f0:2f:74:79:de:79";
      };
      linkConfig = {
        Name = "lan0";
        RxBufferSize = 8184;
        TxBufferSize = 8184;
      };
    };
    networks."10-lan" = {
      matchConfig.Name = "lan0";
      linkConfig.RequiredFamilyForOnline = "both";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
    };

    links."20-downed" = {
      matchConfig = {
        Type = "ether";
        MACAddress = "04:7c:16:cd:c5:cf";
      };
      linkConfig.Name = "downed-lan0";
    };
    networks."20-downed" = {
      matchConfig.Name = "downed-lan0";
      linkConfig.ActivationPolicy = "always-down";
    };

    wait-online = {
      timeout = 20; # seconds
      extraArgs = [
        "--ipv4"
        "--ipv6"
        "--interface=lan0"
      ];
    };
  };
}
