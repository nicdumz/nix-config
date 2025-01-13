# Remember that this already imports https://github.com/nix-community/nixos-generators/blob/master/formats/vm-nogui.nix
_: {
  # Already from my nix modules
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PermitRootLogin = "prohibit-password";
  #   };
  # };
  virtualisation = {
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];
    writableStore = true;
    #useBootLoader = true;
    diskSize = 4 * 1024;
  };
}
