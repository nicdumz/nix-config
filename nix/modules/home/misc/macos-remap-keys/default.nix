{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.macos-remap-keys;
in
{
  options.${namespace}.macos-remap-keys = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Remap the ISO key left of "1" (§/±, NonUSBackslash) to `/~ on macOS,
        via home-manager's services.macos-remap-keys (hidutil + a launchd agent).
      '';
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    services.macos-remap-keys = {
      enable = true;
      keyboard.NonUSBackslash = "GraveAccent";
    };
  };
}
