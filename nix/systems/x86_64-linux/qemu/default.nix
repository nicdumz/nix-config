{ modulesPath, ... }:
{
  # Note: I do this instead of using the snowfall-lib integration "magic" because this then creates
  # the host as a nixosConfigurations which is then part of builds / CI / etc. (vmConfigurations is
  # not recognized).
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  system.stateVersion = "24.11";
  # networking.hostName = "qemu-vm";
  # nicdumz.embedFlake = true; # for fun
}
