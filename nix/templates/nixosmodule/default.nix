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

  config = lib.mkIf cfg.enable {
  };
}
