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
      configureParent = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      parent = {
        user = lib.mkOption { type = lib.types.str; };
        group = lib.mkOption { type = lib.types.str; };
      };
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
    assertions =
      let
        # Plain string entries (e.g. "/etc/ssh" in the base list above) are
        # root-owned and always stable; only the { directory, user, group,
        # ... } form needs checking.
        namedDirs = builtins.filter lib.isAttrs cfg.directories;
        mkAssertion = directory: kind: name: pinned: {
          assertion = pinned;
          message = ''
            ${namespace}.persistence: ${kind} '${name}' owns persisted directory
            '${directory}' but has no explicit id pinned. With mutableUsers =
            false, userborn reallocates every unpinned uid/gid from scratch on
            every boot, so ownership of persisted data silently drifts to
            whatever service happens to land on the same number next time.
            Pin users.users.${name}.uid (or users.groups.${name}.gid).
          '';
        };
        dirAssertions =
          d:
          [
            (mkAssertion d.directory "user" d.user (config.users.users.${d.user}.uid != null))
            (mkAssertion d.directory "group" d.group (config.users.groups.${d.group}.gid != null))
          ]
          ++ lib.optionals d.configureParent [
            (mkAssertion d.directory "parent user" d.parent.user (
              config.users.users.${d.parent.user}.uid != null
            ))
            (mkAssertion d.directory "parent group" d.parent.group (
              config.users.groups.${d.parent.group}.gid != null
            ))
          ];
      in
      lib.concatMap dirAssertions namedDirs;

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
