{
  imports = [
    ./disk.nix
    ./qemu-guest.nix
  ];
  networking.hostName = "nixosvm";
  nicdumz.graphical = true;
}
