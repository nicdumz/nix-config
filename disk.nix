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
    impermanence.nixosModules.impermanence
    disko.nixosModules.disko
  ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # TODO: find some location for configs. With flake I have no reason to
      # have configs there.
      # "/etc/nixos"
      "/etc/ssh"
      # I originally only preserved the fish_history file in this directory but
      # this created noise due to
      # https://github.com/fish-shell/fish-shell/issues/10730
      "/root/.local/share/fish"
      "/var/db/sudo/lectured"
      "/var/lib/fprint"
      "/var/lib/nixos" # for users etc
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/nix/id_rsa"
      "/var/lib/logrotate.status"
    ];
  };

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
