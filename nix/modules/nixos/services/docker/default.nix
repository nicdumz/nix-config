{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.docker;
in
{
  imports = [ ./compose2nix.nix ];

  options.${namespace} = {
    docker = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Docker on host";
      };
    };
    containers =
      let
        uid = builtins.toString config.users.users.ndumazet.uid;
        gid = builtins.toString config.users.groups.users.gid;
      in
      {
        defaultEnvironment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Shared enviroment variables for all containers.";
          default = {
            PGID = gid;
            GID = gid;
            PUID = uid;
            UID = uid;
            USERMAP_GID = gid;
            USERMAP_UID = uid;
            TZ = config.time.timeZone;
          };
        };
        user = lib.mkOption {
          type = lib.types.str;
          description = "User option for all containers. Usually `uid:gid`";
          default = "${uid}:${gid}";
        };
        dataroot = {
          fast = lib.mkOption {
            type = lib.types.str;
            # TODO: Will need to move back to fast
            default = "/media/bigslowdata/dockerstate";
          };
          slow = lib.mkOption {
            type = lib.types.str;
            default = "/media/bigslowdata";
          };
        };
      };
  };
  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      # TODO: what about enableOnBoot
      storageDriver = "btrfs";
      logDriver = "local";
      daemon.settings = {
        bridge = "none"; # explicitly created elsewhere.
        data-root = "/var/lib/dockerstate";
        features = {
          buildkit = true;
        };
        metrics-addr = "127.0.0.1:9323";
        # TODO: this breaks.
        # dns = [ config.${namespace}.myipv4 ];
        experimental = true;
      };
    };
  };
}
