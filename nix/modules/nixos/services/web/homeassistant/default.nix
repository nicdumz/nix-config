{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.homeassistant;
in
{
  options.${namespace}.homeassistant = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Homeassistant";
    };
  };
  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      config = {
        default_config = { };
        api = { };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" ];
        };
      };
      extraPackages =
        python3Packages: with python3Packages; [
          gtts
          pyoverkiz
        ];
    };

    ${namespace} = {
      motd.systemdServices = [ "home-assistant" ];
      traefik.webservices.homeassistant.port = config.services.home-assistant.config.http.server_port;
      persistence.directories = [
        {
          directory = config.services.home-assistant.configDir;
          user = config.users.users.hass.name;
          inherit (config.users.users.hass) group;
        }
      ];
    };
  };
}
