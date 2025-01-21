{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.tailscale;
in
{
  options.${namespace}.tailscale = with lib.types; {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Turn on tailscale on host.";
    };
    useRoutingFeatures = lib.mkOption {
      type = string;
      default = "client";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.tailscale_oauth_token = { };

    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      inherit (cfg) useRoutingFeatures;
      extraUpFlags = [
        "--ssh"
      ];
      # The key is a reusable key from https://login.tailscale.com/admin/settings/keys
      # It unfortunately expires after 90d ..
      authKeyFile = config.sops.secrets.tailscale_oauth_token.path;
    };
  };
}
