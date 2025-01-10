let
  btrfsMountOptions = [
    "defaults"
    "compress-force=zstd"
    "noatime"
    "ssd"
  ];
in
{
  # TODO: there are ways to be smarter here and not repeat ourselves.

  # TODO: actually should be optional swap and disabled for the VM ...
  mkDiskLayout = swapSize: {
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
              name = "ESP";
              label = "boot";
              priority = 1;
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
                extraArgs = [
                  "-n"
                  "boot"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f" # Override existing partition
                  "-L"
                  "btrfs"
                ];
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
                  "/swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = swapSize;
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  mkEncryptedDiskLayout = swapSize: {
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
        device = "/dev/nvme1n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "ESP";
              label = "boot";
              priority = 1;
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
                extraArgs = [
                  "-n"
                  "boot"
                ];
              };
            };
            luks = {
              size = "100%";
              label = "luks";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  # https://0pointer.net/blog/unlocking-luks2-volumes-with-tpm2-fido2-pkcs11-security-hardware-on-systemd-248.html
                  # NOTE: The setup is unfortunately not yet perfectly supported by disko.
                  # On this machine I first set up a LUKS password then added a security key.
                  # (sudo systemd-cryptenroll /dev/nvme0n1p2 --fido2-device=/dev/hidraw1 --fido2-with-client-pin=no --fido2-credential-algorithm=eddsa)
                  crypttabExtraOpts = [
                    "fido2-device=auto"
                  ];
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f" # Override existing partition
                    "-L"
                    "cryptroot"
                  ];
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
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = swapSize;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
