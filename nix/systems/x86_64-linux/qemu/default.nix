{ modulesPath, ... }:
{
  # Note: I do this instead of using the snowfall-lib integration "magic" because this then creates
  # the host as a nixosConfigurations which is then part of builds / CI / etc. (vmConfigurations is
  # not recognized).
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

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
    # Unfortunately this breaks, maybe https://github.com/NixOS/nixpkgs/issues/240086
    # useBootLoader = true;
    # useEFIBoot = true;
    diskSize = 2 * 1024;
    memorySize = 4 * 1024;
    # NOTE: sharedDirectories = is useful if I need to share with the host.
  };
  # nicdumz.embedFlake = true; # for fun
}
