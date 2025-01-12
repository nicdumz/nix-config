{
  config,
  lib,
  namespace,
  ...
}:
{
  services.tailscale = lib.optionalAttrs config.${namespace}.foundPublicKey {
    enable = true;
    openFirewall = true;
    # TODO: "server" or "both" for an exit node
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
    ];
    # The key is a reusable key from https://login.tailscale.com/admin/settings/keys
    # It unfortunately expires after 90d ..
    authKeyFile = config.age.secrets.tailscaleAuthKey.path;
  };
}
