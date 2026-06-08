{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace};
in
{
  config = lib.mkIf cfg.device.isGraphical {
    environment.systemPackages = with pkgs; [ slack ];
  };
}
