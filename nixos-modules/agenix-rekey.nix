{
  config,
  lib,
  self,
  inputs,
  pkgs,
  ...
}:
let
  # (Security keys need to be accessible from the machine creating / rewkeying
  # configs)
  ageMasterIdentities = [
    # `nix-shell -p age-plugin-fido2-hmac` helps generating those.
    ./identities/yubikey-v5-nano.pub
    ./identities/yubikey-v5.pub
    ./identities/yubikey-v5-backup.pub
  ];
  # Relative to flake directory.
  publicKeyRelPath = "nixos-configurations/${config.networking.hostName}/host.pub";
  publicKeyAbsPath = self.outPath + "/" + publicKeyRelPath;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  options = {
    me.foundPublicKey = lib.mkOption {
      type = lib.types.bool;
      default = builtins.pathExists publicKeyAbsPath;
    };
  };

  config.warnings = [
    (lib.mkIf (!config.me.foundPublicKey) ''
      [ndumazet]: no public key configured for target system.

      This means that some features (e.g. Tailscale) are not enabled.

      After initial host provisioning, run:

        ssh-keyscan -qt ssh-ed25519 $host | cut -d' ' -f2,3 > ./${publicKeyRelPath}

      And rebuild NixOS.
    '')
  ];

  config.age.rekey =
    {
      masterIdentities = ageMasterIdentities;
      localStorageDir = self.outPath + "/secrets/rekeyed/${config.networking.hostName}";
      storageMode = "local";
      agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    }
    # Only set the pubkey if we find it.
    // lib.optionalAttrs config.me.foundPublicKey {
      # TODO: put this into the correct file
      # hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcy5s114N7IL5WJIeMh2R7AZE+Gi9f4gVY6u4ZELFWX root@nixos";
      hostPubkey = builtins.readFile publicKeyAbsPath;
    };
}
