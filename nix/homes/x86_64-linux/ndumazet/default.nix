{
  pkgs,
  ...
}:
{
  home.packages = [
    # useful for (shell) color diagnosis.
    pkgs.neofetch
  ];

  nicdumz = {
    irc.enable = true;
    kitty.enable = true;
    librewolf.enable = true;
    vscode.enable = true;
    wallpaper.path = ./nixos-wallpaper.png;
  };
}
