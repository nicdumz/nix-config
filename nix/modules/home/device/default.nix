{
  config,
  lib,
  namespace,
  osConfig ? { },
  ...
}:
{
  options.${namespace}.device = {
    type = lib.mkOption {
      type = lib.types.enum [
        "laptop"
        "desktop"
        "server"
      ];
      default = "server";
      description = "The type of device this HM configuration is evaluating for.";
    };

    isGraphical = lib.mkOption {
      type = lib.types.bool;
      default =
        config.${namespace}.device.type == "laptop" || config.${namespace}.device.type == "desktop";
      description = "Whether to install graphical applications (derived from device type).";
      readOnly = true;
    };
  };

  config = lib.mkIf ((osConfig.${namespace}.device.type or null) != null) {
    ${namespace}.device.type = osConfig.${namespace}.device.type;
  };
}
