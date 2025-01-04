{ inputs, ... }:
let
  btrfsMountOptions = [
    "defaults"
    "compress-force=zstd"
    "noatime"
    "ssd"
  ];
in
{
  imports = with inputs; [
    disko.nixosModules.disko
  ];

  disko.devices = {
    nodev = {
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=4G" # or size=50% ?
          "mode=755"
        ];
        mountpoint = "/";
      };
    };
    disk = {
      main = {
        # When using disko-install, we will overwrite this value from the commandline
        device = "/dev/disk/by-uuid/6133b07e-2e28-4a0a-a3c9-e0561db51866";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = {
                  "home" = {
                    mountOptions = btrfsMountOptions;
                    mountpoint = "/home";
                  };
                  "nix" = {
                    mountOptions = btrfsMountOptions;
                    mountpoint = "/nix";
                  };
                  "persist" = {
                    mountOptions = btrfsMountOptions;
                    mountpoint = "/persist";
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
}
