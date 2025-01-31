{ inputs, pkgs, ... }:
{

  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = inputs.self.outPath + "/secrets/global.yaml";
  # Due to impermanence, need to make sure the SSH keys appear early enough.
  fileSystems."/etc/ssh".neededForBoot = true;

  environment.systemPackages = with pkgs; [
    libfido2 # provides fido2-token utility
  ];
}
