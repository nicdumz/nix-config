# sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#myvm' --disk main /dev/sda

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";

    # Has no releases so far, and not using nixpkgs.
    impermanence.url = "github:nix-community/impermanence";

    # Organize folders according to this predefined structure.
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager.url = "github:nix-community/home-manager?ref=release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-programs-sqlite.url = "github:wamserma/flake-programs-sqlite";
    flake-programs-sqlite.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";

    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    colmena.inputs.stable.follows = "nixpkgs";
  };

  # snowfall rewrite TODOs:
  #  * why cant i set passwords sigh

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          namespace = "nicdumz";
          root = ./nix;
        };
      };
    in
    lib.mkFlake {
      imports = [ inputs.agenix-rekey.flakeModule ];

      outputs-builder = channels: {
        # inlined treefmt config.
        formatter = inputs.treefmt-nix.lib.mkWrapper channels.nixpkgs {
          projectRootFile = "flake.nix";
          settings.global.excludes = [
            "*.age"
            "*.png"
            "*.pub"
          ];
          programs = {
            deadnix.enable = true;
            fish_indent.enable = true;
            mdformat.enable = true;
            mdformat.package = channels.nixpkgs.mdformat.withPlugins (
              p: with p; [
                mdformat-gfm
                mdformat-gfm-alerts
              ]
            );
            nixfmt.enable = true;
            statix.enable = true;
          };
        };

      };

      # Note: due to https://github.com/zhaofengli/colmena/issues/202 /
      # Note: due to https://github.com/zhaofengli/colmena/issues/60 /
      #   https://github.com/zhaofengli/colmena/pull/228, in order to work from a dirty flake dir,
      #   I have to pass
      #     `colmena --experimental-flake-eval build` and friends.
      colmenaHive = lib.mkColmenaHive inputs.self.pkgs.x86_64-linux.nixpkgs {
        bistannix = {
          allowLocalDeployment = true;
          targetHost = null;
        };
        liveusb.targetHost = null;
      };

      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self; # expects the flake itself (not flakedir)
        inherit (inputs.self) nixosConfigurations;
      };
    };
}
