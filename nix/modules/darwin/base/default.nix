{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.base;
in
{
  options.${namespace}.base = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the generic nix-darwin base configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    # This host installs Nix with the Determinate Systems installer, which owns
    # /etc/nix and the nix-daemon launchd service. Letting nix-darwin manage Nix
    # too would fight it, so we explicitly opt out. Substituters / trusted keys
    # live in the user's home-manager nix.settings instead.
    nix.enable = false;

    # Register fish in /etc/shells so it can be used as a login shell.
    programs.fish.enable = true;
  };
}
