{ inputs, ... }:
{
  # Note: I do this instead of using the snowfall-lib integration "magic" because this then creates
  # the host as a nixosConfigurations which is then part of builds / CI / etc. (vmConfigurations is
  # not recognized).
  imports = [ inputs.nixos-generators.nixosModules.vm-nogui ];

  virtualisation = {
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];
    mountHostNixStore = true;
    useBootLoader = true;
    diskSize = 4 * 1024;
    useEFIBoot = true;
    # NOTE: sharedDirectories = is useful if I need to share with the host.
  };
}
