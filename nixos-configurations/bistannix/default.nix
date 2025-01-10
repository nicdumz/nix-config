{ ezModules, inputs, ... }:
{
  imports = [
    ezModules.persistence
    inputs.disko.nixosModules.disko
    ./configuration.nix
    ./windows-dual.nix
  ];

  disko.devices = (import ../../lib).mkEncryptedDiskLayout "32";

  networking.hostName = "bistannix";
  nicdumz.graphical = true;
}
