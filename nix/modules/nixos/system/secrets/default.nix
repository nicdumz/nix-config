{
  config,
  inputs,
  pkgs,
  ...
}:
{

  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = inputs.self.outPath + "/secrets/global.yaml";
  # Due to impermanence, need to make sure the SSH keys appear early enough.
  fileSystems."/etc/ssh".neededForBoot = true;

  environment.systemPackages = with pkgs; [
    libfido2 # provides fido2-token utility
  ];

  # TODO: this could be in home-manager somewhere, but requires setting sops + HM
  sops.secrets.ndumazet_github_token.restartUnits = [ "nix-daemon.service" ];
  sops.templates.ndumazet_nix_extra_config = {
    content = ''
      access-tokens = github.com=${config.sops.placeholder.ndumazet_github_token}
    '';
    owner = "ndumazet";
  };
}
