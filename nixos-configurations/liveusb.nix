{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
  ];
  networking.hostName = "liveusb";
  # Super useful for liveusb, e.g. allows setting up a system from flake inputs.
  nicdumz.embedFlake = true;
}
