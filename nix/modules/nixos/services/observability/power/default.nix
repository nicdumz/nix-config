{ config, namespace, ... }:
{
  config.services = {
    upower.enable = config.${namespace}.device.type == "laptop";
    power-profiles-daemon.enable = config.${namespace}.device.type == "laptop";
  };
}
