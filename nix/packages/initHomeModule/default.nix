{ pkgs, ... }:
pkgs.writeTextFile {
  name = "initHomeModule";
  text = ./initHomeModule.fish;
  destination = "/share/fish/vendor_functions.d/initHomeModule.fish";
  executable = true;
}
