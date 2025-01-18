{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.scaling;
in
{
  options.${namespace}.scaling = {
    defaultFontSize = lib.mkOption {
      type = lib.types.int;
      description = "Default fontsize at the OS level.";
    };
    factor = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Scaling for the UX.";
    };
  };
  config = lib.mkIf cfg.enable {
  };
}
