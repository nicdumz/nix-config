{
  lib,
  pkgs,
  config,
  ...
}:
{
  snowfallorg.users = {
    ndumazet = {
      create = lib.mkDefault true;
      admin = true;
    };
  };

  sops.secrets = {
    ndumazet_hashed_password.neededForUsers = true;
  };

  users = {
    mutableUsers = false;

    users =
      let
        ndumazetKeys = [
          # TODO: formalize this.
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIU3bA3q9/SlrUXzsApLaVkUDAlQY1c5PMmnoC+XnmjOAAAABHNzaDo= ndumazet@bistannix nano"
        ];
      in
      {
        ndumazet = {
          isNormalUser = true;
          extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
          createHome = true;
          uid = 1000; # Debian defaults.
          openssh.authorizedKeys.keys = ndumazetKeys;
          hashedPasswordFile = config.sops.secrets.ndumazet_hashed_password.path;
        };

        root = {
          # NOTE: no passwd, no need for direct login.
          uid = 0;
          openssh.authorizedKeys.keys = ndumazetKeys;
        };
      };

    defaultUserShell = pkgs.fish;
  };
  # This is technically needed to not have assertions failing due to
  # defaultUserShell. But actual configuration happens in home-manager below.
  programs.fish.enable = true;

  # If the user is created I always want a home-configuration for it.
  assertions =
    let
      createAssert = n: v: {
        assertion = !v.create || (builtins.hasAttr n config.home-manager.users);
        message = "${config.networking.hostName}: user '${n}' will be created but has no home configuration";
      };
    in
    lib.attrsets.mapAttrsToList createAssert config.snowfallorg.users;
}
