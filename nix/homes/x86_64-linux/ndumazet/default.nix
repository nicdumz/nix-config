{
  osConfig ? { },
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
    chrome.enable = true;
    vscode.enable = true;
    wallpaper.path = ./nixos-wallpaper.png;
  };
  nix.extraOptions = ''
    !include ${osConfig.sops.templates.ndumazet_nix_extra_config.path or "/dev/null"}
  '';
}
