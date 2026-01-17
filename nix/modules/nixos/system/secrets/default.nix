{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{

  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = inputs.self.outPath + "/secrets/global.yaml";
    # TODO: this could be in home-manager somewhere, but requires setting sops + HM
    secrets.ndumazet_github_token.restartUnits = [ "nix-daemon.service" ];
    templates.ndumazet_nix_extra_config = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.ndumazet_github_token}
      '';
      owner = "ndumazet";
    };
  };
  # TODO: upstream
  systemd.services =
    let
      files =
        config.sops.age.sshKeyPaths
        ++ (lib.lists.optional (config.sops.age.keyFile != null) config.sops.age.keyFile);
    in
    {
      sops-install-secrets.unitConfig.RequiresMountsFor = files;
      sops-install-secrets-for-users.unitConfig.RequiresMountsFor = files;
    };

  environment.systemPackages = with pkgs; [
    libfido2 # provides fido2-token utility
  ];
}
