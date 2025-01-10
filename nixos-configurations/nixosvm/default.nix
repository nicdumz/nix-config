{ ezModules, inputs, ... }:
{
  imports = [
    ezModules.persistence
    inputs.disko.nixosModules.disko
    ./qemu-guest.nix
  ];

  disko.devices = (import ../../lib).mkDiskLayout "16G";

  networking.hostName = "nixosvm";
  nicdumz.graphical = true;
}
