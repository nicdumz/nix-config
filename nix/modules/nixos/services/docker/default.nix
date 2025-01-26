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

  options.${namespace}.docker = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Docker on host";
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
