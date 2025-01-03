{
  config,
  lib,
  self,
  inputs,
  ...
}:
let
  # TODO: should eventually be a bunch of FIDO2 fprints.
  # (Security keys need to be accessible from the machine creating / rewkeying
  # configs)
  ageMasterIdentities = [
    # https://github.com/str4d/age-plugin-yubikey helps generating those, e.g.
    # `nix-shell -p age-plugin-yubikey usbutils` and hack away.
    ./identities/yubikey-v4-nano-identity.pub
  ];
  # Relative to flake directory.
  publicKeyRelPath = "identities/host/${config.networking.hostName}.pub";
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
    }
    # Only set the pubkey if we find it.
    // lib.optionalAttrs config.me.foundPublicKey {
      # TODO: put this into the correct file
      # hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcy5s114N7IL5WJIeMh2R7AZE+Gi9f4gVY6u4ZELFWX root@nixos";
      hostPubKey = builtins.readFile config.me.publicKeyPath;
    };
}
