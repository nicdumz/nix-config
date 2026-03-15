{
  inputs,
  namespace,
  config,
  lib,
  ...
}:
let
  cfg = config.${namespace}.persistence;

  directoryWithPerms = lib.types.submodule {
    options = {
      directory = lib.mkOption { type = lib.types.str; };
      user = lib.mkOption { type = lib.types.str; };
      group = lib.mkOption { type = lib.types.str; };
    };
  };
in
{
  imports = [
    inputs.preservation.nixosModules.preservation
  ];

  options.${namespace}.persistence = {
    enable = lib.mkEnableOption "Enable persistence";

    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str directoryWithPerms);
      default = [ ];
      description = "Directories to persist.";
    };
  };
  config = lib.mkIf cfg.enable {
    preservation = {
      enable = true;
      preserveAt."/persist" = {
        commonMountOptions = [ "x-gvfs-hide" ];
        directories = [
          "/etc/ssh"
          # I originally only preserved the fish_history file in this directory but
          # this created noise due to
          # https://github.com/fish-shell/fish-shell/issues/10730
          "/root/.local/share/fish"
          "/var/cache"
          "/var/db/sudo"
          # NOTE: List below is experimental, it used to be "/var/lib"
          "/var/lib/bluetooth"
          "/var/lib/NetworkManager"
          "/var/lib/nixos"
          "/var/lib/systemd/timers"
          "/var/log"
          # NM networks.
          "/etc/NetworkManager/system-connections"
        ]
        ++ cfg.directories;
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/etc/nix/id_rsa";
            inInitrd = true;
          }
          "/var/lib/logrotate.status"
        ];
      };
    };

    # systemd-machine-id-commit.service would fail, but it is not relevant
    # in this specific setup for a persistent machine-id so we disable it
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    # TODO: is there a useable way to set this up on home directories and not end up in a world of
    # hurt and regret.

    fileSystems."/".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;
  };
}
