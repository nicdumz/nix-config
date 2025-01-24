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
      # Do I need this?
      storageDriver = "btrfs";
      # previously was "storage-driver": "overlay2" on host
      logDriver = "local";
      rootless = {
        # TODO: this might break /var/run/docker.sock users
        enable = true;
        setSocketVariable = true;
      };
      daemon.settings = {
        data-root = "/var/lib/dockerstate";
        features = {
          buildkit = true;
        };
        metrics-addr = "0.0.0.0:9323";
        experimental = true;
      };
    };
  };
}
