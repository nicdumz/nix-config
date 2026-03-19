{
  config,
  lib,
  namespace,
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
      description = "The type of device exactly governing system functionality.";
    };

    isGraphical = lib.mkOption {
      type = lib.types.bool;
      default =
        config.${namespace}.device.type == "laptop" || config.${namespace}.device.type == "desktop";
      description = "Whether to install graphical applications (derived from device type).";
      readOnly = true;
    };
  };
}
