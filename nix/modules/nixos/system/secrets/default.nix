{
  config,
  inputs,
  pkgs,
  ...
}:
{

  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = inputs.self.outPath + "/secrets/global.yaml";
    # Due to impermanence, need to make sure the SSH keys appear early enough.
    #
    # Default for this setting would point to /etc/ssh/... which may not be
    # mounted by the time the system boots and needs secrets for login.
    age.sshKeyPaths = [
      "/persist/etc/ssh/ssh_host_ed25519_key"
    ];

    # TODO: this could be in home-manager somewhere, but requires setting sops + HM
    secrets.ndumazet_github_token.restartUnits = [ "nix-daemon.service" ];
    templates.ndumazet_nix_extra_config = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.ndumazet_github_token}
      '';
      owner = "ndumazet";
    };
  };

  environment.systemPackages = with pkgs; [
    libfido2 # provides fido2-token utility
  ];
}
