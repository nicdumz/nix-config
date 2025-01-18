{
  namespace,
  lib,
  pkgs,
  config,
  ...
}:
{
  snowfallorg.users = {
    ndumazet = {
      create = true;
      admin = true;
      home.config.${namespace} = {
        irc.enable = true;
        kitty.enable = true;
        librewolf.enable = true;
        vscode.enable = true;

      };
    };
    giulia = {
      # Do not enable by default, opt-in.
      create = lib.mkDefault false;
      admin = false;
      home.config.${namespace} = {
        chrome.enable = true;
      };
    };
  };

  sops.secrets = {
    ndumazet_hashed_password.neededForUsers = true;
    giulia_hashed_password.neededForUsers = true;
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

        giulia = {
          isNormalUser = true;
          hashedPasswordFile = config.sops.secrets.giulia_hashed_password.path;
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
}
