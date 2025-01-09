{
  imports = [
    ./disk.nix
    ./configuration.nix
    ./windows-dual.nix
  ];
  networking.hostName = "bistannix";
  nicdumz.graphical = true;
}
