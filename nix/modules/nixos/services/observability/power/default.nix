{ config, namespace, ... }:
{
  config.services.upower.enable = config.${namespace}.device.type == "laptop";
}
