# sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#myvm' --disk main /dev/sda

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Has no releases so far, and not using nixpkgs.
    impermanence.url = "github:nix-community/impermanence";

    # Organize folders according to this predefined structure.
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

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
      # Simplify eval, do not generate all systems ...
      supportedSystems = [ "x86_64-linux" ];

      channels-config = {
        allowUnfree = true;
      };

      outputs-builder = channels: {
        # inlined treefmt config.
        formatter = inputs.treefmt-nix.lib.mkWrapper channels.nixpkgs {
          projectRootFile = "flake.nix";
          settings.global.excludes = [
            "*.age"
            "*.code-snippets"
            "*.png"
            "*.pub"
            "*.webp"
            ".editorconfig"
            ".envrc"
            "LICENSE"
          ];
          programs = {
            deadnix.enable = true;
            fish_indent.enable = true;
            mdformat = {
              enable = true;
              package = channels.nixpkgs.mdformat.withPlugins (
                p: with p; [
                  mdformat-gfm
                  # TODO: broken in 25.05
                  # mdformat-gfm-alerts
                ]
              );
              settings.wrap = 100;
            };
            nixfmt.enable = true;
            statix.enable = true;
            yamlfmt.enable = true;
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

      # This loads a vm in the current shell:
      #   nix build .#qemu-vm && ./result/bin/run-qemu-vm
      # Log into it via ssh:
      #   ssh -p 2222 root@localhost
      qemu-vm = inputs.self.nixosConfigurations.qemu.config.system.build.vm;

      templates = {
        # Sigh somehow templates were never added to git, https://snowfall.org/guides/lib/templates/
        # homemodule.description = "Simple Snowfall lib Home module template";
        # nixosmodule.description = "Simple Snowfall lib NixOS module template";
      };
    };
}
