{
  osConfig ? { },
  pkgs,
  ...
}:
{
  home.packages = [
    # useful for (shell) color diagnosis.
    pkgs.neofetch
    pkgs.dig
  ];

  nicdumz = {
    irc.enable = true;
    kitty.enable = true;
    chrome.enable = true;
    vscode.enable = true;
    wallpaper.path = ./nixos-wallpaper.png;
  };
  nix.extraOptions = ''
    !include ${osConfig.sops.templates.ndumazet_nix_github_access_token.path or "/dev/null"}
  '';
}
