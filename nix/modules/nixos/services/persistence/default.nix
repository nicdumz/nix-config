{
  inputs,
  namespace,
  config,
  lib,
  ...
}:
let
  cfg = config.${namespace}.persistence;
in
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  options.${namespace}.persistence.enable = lib.mkEnableOption "Enable persistence";
  config = lib.mkIf cfg.enable {
    environment.persistence."/persist" = {
      hideMounts = true;
      directories =
        [
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
        # TODO: make a directory option and let modules declare this
        ++ lib.lists.optionals config.${namespace}.docker.enable [
          "/var/lib/dockerstate"
        ]
        ++ lib.lists.optionals config.${namespace}.prometheus.enable [
          "/var/lib/prometheus2"
        ]
        ++ lib.lists.optionals config.${namespace}.tailscale.enable [
          "/var/lib/tailscale" # maybe play without this to see what actually happens.
        ]
        ++ lib.lists.optionals config.${namespace}.traefik.enable [
          "/var/lib/traefik"
        ]
        ++ lib.lists.optionals config.${namespace}.loki.enable [
          "/var/lib/loki"
        ];
      files = [
        "/etc/machine-id"
        "/etc/nix/id_rsa"
        "/var/lib/logrotate.status"
      ];
    };

    # TODO: is there a useable way to set this up on home directories and not end up in a world of
    # hurt and regret.

    fileSystems."/".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;
  };
}
