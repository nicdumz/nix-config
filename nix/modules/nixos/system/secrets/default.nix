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

    secrets = {
      # TODO: this could be in home-manager somewhere, but requires setting sops + HM
      ndumazet_github_token.restartUnits = [ "nix-daemon.service" ];

      # used in home-manager
      weather_api_key = { };

      # nix-ci.com (and its api/cache subdomains) share one login/password pair.
      nix_ci_username = { };
      nix_ci_password = { };
    };

    templates = {
      ndumazet_nix_github_access_token = {
        content = ''
          access-tokens = github.com=${config.sops.placeholder.ndumazet_github_token}
        '';
        owner = "ndumazet";
      };

      weather_api_key = {
        content = ''
          { "weather_api_key": "${config.sops.placeholder.weather_api_key}" }
        '';
        owner = "ndumazet";
      };

      ndumazet_netrc = {
        content = ''
          machine nix-ci.com
            login ${config.sops.placeholder.nix_ci_username}
            password ${config.sops.placeholder.nix_ci_password}
          machine api.nix-ci.com
            login ${config.sops.placeholder.nix_ci_username}
            password ${config.sops.placeholder.nix_ci_password}
          machine cache.nix-ci.com
            login ${config.sops.placeholder.nix_ci_username}
            password ${config.sops.placeholder.nix_ci_password}
        '';
        path = "/home/ndumazet/.netrc";
        owner = "ndumazet";
        mode = "0400";
      };
    };
  };
  # TODO: in-progress-upstream (https://github.com/Mic92/sops-nix/pull/928)
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
  # Yubico
  services.pcscd.enable = true;
}
