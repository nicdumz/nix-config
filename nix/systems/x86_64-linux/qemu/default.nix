{ inputs, ... }:
{
  # This was useful to mount a shared folder with the host, but I pass around nix configs
  # differently now. Keeping for reference.
  # Note that virtualisation has support
  # fileSystems."/media/host" = {
  #   device = "shared0";
  #   fsType = "9p";
  #   options = [
  #     "trans=virtio"
  #     "version=9p2000.L"
  #     "posixacl"
  #     "cache=mmap"
  #   ];
  # };

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
    writableStore = true;
    # NOTE: virtualisation.mountHostNixStore uses `!cfg.useNixStoreImage && !cfg.useBootLoader` as a
    # default and I imagine this may be why this breaks
    #useBootLoader = true;
    diskSize = 4 * 1024;
  };
}
