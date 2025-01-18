{
  config,
  lib,
  namespace,
  osConfig ? { },
  ...
}:
let
  cfg = config.${namespace}.irc;
in
{
  options.${namespace}.irc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IRC clients.";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: lacks configuration
    programs.irssi.enable = true;
    programs.hexchat.enable = osConfig.${namespace}.graphical or false;
  };
}
