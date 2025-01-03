# sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#myvm' --disk main /dev/sda

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";

    # Has no releases so far, and not using nixpkgs.
    impermanence.url = "github:nix-community/impermanence";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    agenix-rekey.url = "github:oddlama/agenix-rekey";
    # Make sure to override the nixpkgs version to follow your flake,
    # otherwise derivation paths can mismatch (when using storageMode = "derivation"),
    # resulting in the rekeyed secrets not being found!
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.agenix-rekey.flakeModule
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          formatter = pkgs.nixfmt-rfc-style;
          # Add `config.agenix-rekey.package` to your devshell to
          # easily access the `agenix` command wrapper.
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [ config.agenix-rekey.package ];
          };
        };
      # This is the non-per-system variant.
      flake = {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          modules = [
            ./disk.nix
            ./qemu-guest.nix
            ./configuration.nix
          ];
          specialArgs = { inherit inputs self nixpkgs; };
        };
        # This is the default
        #agenix-rekey.nixosConfigurations = inputs.self.nixosConfigurations;
      };
    };
}
