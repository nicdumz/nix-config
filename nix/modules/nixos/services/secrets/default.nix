{ inputs, ... }:
{

  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = inputs.self.outPath + "/secrets/global.yaml";
}
