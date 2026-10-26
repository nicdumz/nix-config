# sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#myvm' --disk main /dev/sda

{
  # Must match nix.settings.substituters/trusted-public-keys in
  # nix/modules/nixos/cli/nix/default.nix verbatim -- nixConfig can only be
  # plain literals (not even a bare `import`), so it can't read that module's
  # settings directly. An assertion in that module fails `nix flake check`
  # if these two ever drift apart.
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://noctalia.cachix.org"
      "https://herdr.cachix.org"
      "https://herdr-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "herdr.cachix.org-1:3nH7IStRsS0ASfdonA0DCRR2ZrSCeWitZ7Kwew0cR4I="
      "herdr-nix.cachix.org-1:UpdsQYx39PK0PToKQaa2EFq19Lsjs1M9Ho+X7VNt9gs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Has no releases so far, and not using nixpkgs.
    preservation.url = "github:nix-community/preservation";

    # Organize folders according to this predefined structure.
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Tracks master, not a release branch: the only home-manager with
    # modules/programs/herdr.nix, which we source by path below (not
    # copied/vendored) since it hasn't landed on a release branch yet. Drop
    # this input and switch to home-manager's own module once it has.
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # macOS system configuration. Input MUST be named `darwin` for snowfall-lib
    # to generate darwinConfigurations and integrate home-manager.
    darwin = {
      url = "github:nix-darwin/nix-darwin?ref=nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Trampolines nix-store .app bundles into ~/Applications so Spotlight and
    # Launchpad can find GUI apps installed via nixpkgs (kitty, vscodium, ...).
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # mac-app-util pins its OWN nixpkgs deliberately (its SBCL/cl-nix-lite Lisp
      # toolchain only builds against that pin — following ours breaks it), so we
      # leave inputs.nixpkgs alone. But its dev-only extras (cl-nix-lite's nixpkgs
      # and the treefmt-nix copies, "not used for actual overlay") are collapsed
      # onto our inputs so the tree doesn't track them as separate nixpkgs.
      inputs = {
        treefmt-nix.follows = "treefmt-nix";
        cl-nix-lite.inputs.nixpkgs.follows = "nixpkgs";
        cl-nix-lite.inputs.treefmt-nix.follows = "treefmt-nix";
      };
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

    flake-checker = {
      url = "github:DeterminateSystems/flake-checker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      # Track main (not release-26.05): the release branch's vscode theme still
      # builds with pnpm_10, which nixpkgs now flags as insecure. main already
      # builds with pnpm_11, so follow nixpkgs-unstable (which main itself
      # targets, and which becomes the next stable release in a few weeks).
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    oh-my-pi = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Official prebuilt-binary packaging of herdr itself (cachix: herdr.cachix.org).
    # NOT the same project as herdr-plugins below, despite the similar name.
    herdr = {
      url = "github:herdrdev/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Third-party herdr plugin packaging + the home-manager module that
    # registers them (cachix: herdr-nix.cachix.org). Unrelated maintainer to
    # the official herdr-nix above.
    herdr-plugins = {
      url = "github:lorenzorapetti/herdr-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        # Its checks activate against programs.herdr, which only exists on
        # home-manager-unstable (see above) -- follow the same input, not
        # our release-26.05 home-manager.
        home-manager.follows = "home-manager-unstable";
      };
    };
    noctalia = {
      # v5 (native runtime). The `cachix` branch tracks the latest commit already
      # pushed to noctalia.cachix.org. Overriding its nixpkgs (follows) would change
      # the derivation hash and force a local build, so it is intentionally not set.
      url = "github:noctalia-dev/noctalia/cachix";
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
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      channels-config = {
        allowUnfree = true;
      };

      outputs-builder = channels: {
        checks =
          channels.nixpkgs.lib.optionalAttrs (channels.nixpkgs.stdenv.hostPlatform.system == "x86_64-linux")
            (builtins.mapAttrs (_name: cfg: cfg.config.system.build.toplevel) inputs.self.nixosConfigurations);

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
            # TODO: fix me
            "docs/*.md"
          ];
          programs = {
            deadnix.enable = true;
            fish_indent.enable = true;
            mdformat = {
              enable = true;
              package = channels.nixpkgs.mdformat.withPlugins (
                p: with p; [
                  mdformat-mkdocs
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

      colmenaHive = lib.mkColmenaHive inputs.self.pkgs.x86_64-linux.nixpkgs {
        bistannix = {
          allowLocalDeployment = true;
          targetHost = null;
        };
        lethargyfamily.allowLocalDeployment = true;
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
