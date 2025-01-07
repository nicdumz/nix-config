# sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#myvm' --disk main /dev/sda

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";

    # Has no releases so far, and not using nixpkgs.
    impermanence.url = "github:nix-community/impermanence";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    home-manager.url = "github:nix-community/home-manager?ref=release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";

    agenix-rekey.url = "github:oddlama/agenix-rekey";
    # Make sure to override the nixpkgs version to follow your flake,
    # otherwise derivation paths can mismatch (when using storageMode = "derivation"),
    # resulting in the rekeyed secrets not being found!
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";

    nova-vim.url = "github:nicdumz/nova-vim";
    nova-vim.flake = false;
  };

  outputs =
    {
      self,
      ez-configs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ez-configs.flakeModule
        inputs.agenix-rekey.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      # see https://github.com/ehllie/ez-configs/blob/main/README.md
      ezConfigs = {
        root = ./.;
        globalArgs = { inherit inputs self; };
        # TODO: ideally this should not be needed?
        nixos.hosts.bistannix.userHomeModules = [
          "ndumazet"
          "root"
        ];
        nixos.hosts.nixosvm.userHomeModules = [
          "ndumazet"
          "root"
        ];
      };

      perSystem =
        {
          config,
          # self',
          # inputs',
          pkgs,
          # system,
          ...
        }:
        {
          # Add `config.agenix-rekey.package` to your devshell to
          # easily access the `agenix` command wrapper.
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              config.agenix-rekey.package
              pkgs.age-plugin-fido2-hmac
            ];
          };
          # This is the default
          #agenix-rekey.nixosConfigurations = inputs.self.nixosConfigurations;

          pre-commit.settings.hooks.treefmt.enable = true;

          # `nix fmt` now does magic in this directory.
          treefmt = {
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
              nixfmt.enable = true;
              statix.enable = true;
            };
          };
        };
      /*
        Here I'm missing the iso, it's OK.
           # This is the non-per-system variant.
           flake = {
             nixosConfigurations =
               let
                 mkSystem =
                   hostname:
                   {
                     system ? "x86_64-linux",
                     modules,
                   }:

                   nixpkgs.lib.nixosSystem {
                     system = system;
                     specialArgs = { inherit inputs self nixpkgs; };
                     modules = modules ++ [
                       inputs.home-manager.nixosModules.home-manager
                       {
                         networking.hostName = hostname;
                         # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
                         system.stateVersion = "24.11"; # Did you read the comment?
                       }
                     ];
                   };
               in
               nixpkgs.lib.mapAttrs mkSystem {
                 iso = {
                   modules = [
                     ./nix.nix
                     "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
                   ];
                 };
               };
           };
      */
    };
}
