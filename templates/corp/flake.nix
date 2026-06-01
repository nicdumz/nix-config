{
  description = "Corp (Work) Home Manager configuration of ndumazet@";

  inputs = {
    # 1. Let upstream be the "source of truth"
    nicdumz.url = "github:nicdumz/nix-config";
    # 2. others follow me
    nixpkgs.follows = "nicdumz/nixpkgs";
    home-manager = {
      follows = "nicdumz/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pam-shim.url = "github:Cu3PO42/pam_shim";
    nixGL.url = "github:nix-community/nixGL";
  };

  outputs =
    {
      nicdumz,
      nixGL,
      nixpkgs,
      pam-shim,
      ...
    }:
    {
      inherit (nicdumz) formatter;

      homeConfigurations =
        builtins.mapAttrs
          (
            _machineName: deviceType:
            nicdumz.lib.mkCorpHome {
              inherit nixpkgs nicdumz deviceType;
              overlays = [ nixGL.overlay ];
              systemLinks = [
                # Note: cannot add git here because functional tests
                # actually try "fun" overrides...
                "hypridle"
                {
                  packageName = "hyprland";
                  programNames = [
                    "hyprland"
                    "hyprctl"
                    "Hyprland"
                  ];
                  version = "0.53.3";
                }
                {
                  packageName = "xdg-desktop-portal-hyprland";
                  directory = "/usr/libexec";
                }
                "hyprlock"
                "hyprpaper"
                {
                  packageName = "jujutsu";
                  programNames = [ "jj" ];
                }
                "kitty"
                {
                  packageName = "google-chrome";
                  programNames = [
                    "google-chrome-stable"
                    "google-chrome"
                  ];
                }
                {
                  packageName = "mercurial";
                  programNames = [ "hg" ];
                }
                "swaylock"
                "wlogout"
              ];
              localModules = [
                ./home.nix
                pam-shim.homeModules.default
              ];
            }
          )
          {
            "ndumazet@machine1.work.host" = "server";
            "ndumazet@machine2.work.host" = "laptop";
            "ndumazet@machine3.work.host" = "desktop";
          };
    };
}
