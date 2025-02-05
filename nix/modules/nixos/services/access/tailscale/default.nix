{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.tailscale;
  exitNode = cfg.exitNode.wanInterface != "";
in
{
  options.${namespace}.tailscale = with lib.types; {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Turn on tailscale on host.";
    };
    exitNode.wanInterface = lib.mkOption {
      type = str;
      description = "Make this host an exit node? If yes, let me know what is the wan interface.";
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.tailscale_oauth_token = { };

    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # Note: we could play with not persisting this to see what happens.
    ${namespace}.persistence.directories = [ "/var/lib/tailscale" ];

    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = if exitNode then "both" else "client";
      extraUpFlags = [ "--ssh" ];
      extraSetFlags = lib.lists.optionals exitNode [ "--advertise-exit-node" ];
      # The key is a reusable key from https://login.tailscale.com/admin/settings/keys
      # It unfortunately expires after 90d ..
      authKeyFile = config.sops.secrets.tailscale_oauth_token.path;
    };

    systemd.services.tailscale-transport-layer-offloads = lib.mkIf exitNode {
      # See https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration.
      description = "Tailscale: better performance for exit nodes";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.ethtool}/bin/ethtool -K ${cfg.exitNode.wanInterface} rx-udp-gro-forwarding on rx-gro-list off";
      };
      wantedBy = [ "default.target" ];
    };

    environment.systemPackages = lib.lists.optionals exitNode [ pkgs.ethtool ];
  };
}
