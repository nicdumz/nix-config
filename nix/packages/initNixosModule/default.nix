{ pkgs, ... }:
pkgs.writeTextFile {
  name = "initNixosModule";
  text = ./initNixosModule.fish;
  destination = "/share/fish/vendor_functions.d/initNixosModule.fish";
  executable = true;
}
