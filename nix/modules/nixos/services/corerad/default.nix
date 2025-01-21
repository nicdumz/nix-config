{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.corerad;
in
{
  options.${namespace}.corerad = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Corerad integration";
    };
    lan = lib.mkOption {
      type = lib.types.str;
      description = "lan interface";
    };
    wan = lib.mkOption {
      type = lib.types.str;
      description = "wan interface";
    };
  };
  config = lib.mkIf cfg.enable {
    services.corerad.enable = true;
    services.corerad.settings = {
      interfaces = [
        {
          name = cfg.lan;
          advertise = true;
          prefix = [
            # RFC8978: Reaction of IPv6 SLAAC to Flash-Renumbering Events
            {
              preferred_lifetime = "45m";
              valid_lifetime = "90m";
            }
          ];

          # Automatically use the appropriate interface address as a DNS server.
          rdnss = [ { } ];

          # Automatically propagate routes owned by loopback.
          route = [
            # Tuning inspired by:
            # RFC8978: Reaction of IPv6 SLAAC to Flash-Renumbering Events
            { lifetime = "45m"; }
          ];
        }
        {
          name = cfg.wan;
          monitor = true;
        }
      ];
      debug = {
        # no hosts aka listen/bind on all hosts, but firewall will not be open to outsiders.
        address = ":9430";
        prometheus = true;
      };
    };
  };
}
