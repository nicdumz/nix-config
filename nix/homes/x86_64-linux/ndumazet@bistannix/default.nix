{
  pkgs,
  osConfig ? { },
  lib,
  inputs,
  namespace,
  ...
}:
{
  imports = [
    ./kitty.nix
    ./vscode.nix
    # TODO: move to an actual module, it's ignored because of /this/ default.nix
    ./app/librewolf
  ];

  # TODO: lacks configuration
  programs.irssi.enable = true;
  programs.hexchat.enable = osConfig.${namespace}.graphical or false;

  home.packages = [
    # useful for (shell) color diagnosis.
    pkgs.neofetch
  ];

  # A strange one: embed the flake entire directory onto the produced system. This allows having
  # access to the input .nix files, and is convenient when building an .iso which then can be used
  # for deployment.
  home.file.nixos-sources = lib.mkIf (osConfig.${namespace}.embedFlake or false) {
    source = inputs.self;
    target = "nixos-sources";
  };
}
