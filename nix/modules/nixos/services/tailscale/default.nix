{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.nvidia;
in
{
  options.${namespace}.tailscale = with lib.types; {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Turn on tailscale on host.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.tailscale_oauth_token = { };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      # TODO: "server" or "both" for an exit node
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--ssh"
      ];
      # The key is a reusable key from https://login.tailscale.com/admin/settings/keys
      # It unfortunately expires after 90d ..
      authKeyFile = config.sops.secrets.tailscale_oauth_token.path;
    };
  };
}
