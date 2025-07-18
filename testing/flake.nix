# Run the following to get a clean VM:
# nixos-rebuild build-vm-with-bootloader --flake ./testing#qemu && ./result/bin/run-qemu-vm-vm
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
  };

  outputs = inputs: {
    # Available through 'nixos-rebuild --flake ./testing#qemu
    nixosConfigurations.qemu = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        {
          services.openssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIU3bA3q9/SlrUXzsApLaVkUDAlQY1c5PMmnoC+XnmjOAAAABHNzaDo= ndumazet@bistannix nano"
          ];
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          # Note: my manual tests try to figure out if I can update machine/users/password and not
          # brick my host.
          users.users.ndumazet = {
            password = "testing";
            isNormalUser = true;
          };

          virtualisation = {
            graphics = false;
            qemu.options = [ "-serial mon:stdio" ];

            forwardPorts = [
              {
                from = "host";
                host.port = 2222;
                guest.port = 22;
              }
            ];
            mountHostNixStore = true;
            useBootLoader = true;
            useEFIBoot = true;
            diskSize = 10 * 1024;
            memorySize = 8 * 1024;
            # NOTE: sharedDirectories = is useful if I need to share with the host.
          };
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "25.05";
          networking.hostName = "qemu-vm";
        }
      ];
    };
  };
}
