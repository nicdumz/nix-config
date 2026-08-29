{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.plex;
in
{
  options.${namespace}.plex = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Plex: Watch things.";
    };
  };
  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;

    services.plex = {
      enable = true;
      group = "media";
    };
    users.groups.media = { };
    # For hardware rendering
    users.users.plex.extraGroups = [
      "render"
      "video"
    ];

    ${namespace} = {
      motd.systemdServices = [ "plex" ];
      persistence.directories = [
        {
          directory = config.services.plex.dataDir;
          inherit (config.services.plex) user group;
          configureParent = true;
          parent = {
            inherit (config.services.plex) user group;
          };
        }
      ];
      # unfortunately not exposed in the service config.
      traefik.webservices.plex.port = 32400;
      # Same ports services.plex.openFirewall would open, but LAN-scoped instead
      # of global: 32400 for the web UI (also needed for the browser-side
      # local-network check during claim/setup), 3005/8324/32469 for
      # companion/Roku/DLNA, and the UDP ports for GDM/SSDP discovery.
      firewall = {
        tcp = [
          32400
          3005
          8324
          32469
        ];
        udp = [
          1900
          5353
          32410
          32412
          32413
          32414
        ];
      };
    };
  };
}
