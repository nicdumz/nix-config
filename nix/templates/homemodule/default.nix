{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.module;
in
{
  options.${namespace}.module = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ...";
    };
  };

  config =
    # TODO: consider (osConfig.${namespace}.graphical or false) pattern
    lib.mkIf cfg.enable {
    };
}
