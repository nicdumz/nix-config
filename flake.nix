# sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#myvm' --disk main /dev/sda

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";

    # Has no releases so far
    impermanence.url = "github:nix-community/impermanence";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # Sigh why are those gymnastics needed.
    # See https://github.com/cachix/git-hooks.nix/issues/542
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    };
    # pre-commit-hooks."nixpkgs-stable".follows = "nixpkgs";
    # Make sure to override the nixpkgs version to follow your flake,
    # otherwise derivation paths can mismatch (when using storageMode = "derivation"),
    # resulting in the rekeyed secrets not being found!
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,

      agenix,
      agenix-rekey,
      disko,
      impermanence,

      ...
    }:
    {

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      # https://nixos.wiki/wiki/Automatic_system_upgrades
      system.autoUpgrade = {
        enable = true;
        flake = self.outPath;
        flags = [
          "--update-input"
          "nixpkgs"
          "-L" # print build logs
        ];
        dates = "02:00";
        randomizedDelaySec = "45min";
      };

      # Expose the necessary information in your flake so agenix-rekey
      # knows where it has too look for secrets and paths.
      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations;
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        modules = [
          impermanence.nixosModules.impermanence
          ./disk.nix
          ./qemu-guest.nix
          ./configuration.nix
          disko.nixosModules.disko
          agenix.nixosModules.default
          agenix-rekey.nixosModules.default
        ];
      };
    };
}
