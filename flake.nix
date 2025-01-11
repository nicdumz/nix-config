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

    nova-vim.url = "github:nicdumz/nova-vim";
    nova-vim.flake = false;

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    colmena.inputs.stable.follows = "nixpkgs";
  };

  # snowfall rewrite TODOs:
  #  * why cant i set passwords sigh

  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      imports = [ inputs.agenix-rekey.flakeModule ];

      snowfall = {
        namespace = "nicdumz";
        root = ./nix;
      };

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
      #   https://github.com/zhaofengli/colmena/pull/228, in order to work from a dirty flake dir,
      #   I have to pass
      #     `colmena --experimental-flake-eval build` and friends.
      colmenaHive = inputs.colmena.lib.makeHive inputs.self.outputs.colmena;
      colmena =
        let
          conf = inputs.self.nixosConfigurations;
        in
        {
          meta = {
            nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
            nodeNixpkgs = builtins.mapAttrs (_name: value: value.pkgs) conf;
            nodeSpecialArgs = builtins.mapAttrs (_name: value: value._module.specialArgs) conf;
          };

          bistannix = {
            deployment = {
              allowLocalDeployment = true;
              targetHost = null;
            };
          };
          lethargyfamily = { };
        }
        // builtins.mapAttrs (_name: value: { imports = value._module.args.modules; }) conf;

      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self; # expects the flake itself (not flakedir)
        inherit (inputs.self) nixosConfigurations;
      };
    };
}
