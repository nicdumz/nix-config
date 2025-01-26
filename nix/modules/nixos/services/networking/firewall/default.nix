{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.firewall;
in
{
  options.${namespace}.firewall = {
    interface = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Interface to open ports on";
    };
    udp = lib.mkOption {
      type = lib.types.listOf lib.types.port;
    };
    tcp = lib.mkOption {
      type = lib.types.listOf lib.types.port;
    };
  };
  config = lib.mkIf (cfg.interface != "") {
    networking.firewall.interfaces.${cfg.interface} = {
      allowedTCPPorts = cfg.tcp;
      allowedUDPPorts = cfg.udp;
    };
  };
}
