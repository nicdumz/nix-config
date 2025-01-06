{ ... }:
{
  imports = [
    ./kitty.nix
    ./vscode.nix
  ];
  home.username = "ndumazet";

  programs.git = {
    userEmail = "nicdumz.commits@gmail.com";
    userName = "Nicolas Dumazet";
  };

  programs.librewolf = {
    enable = true;
    settings =
      let
        ext = name: "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
      in
      {
        # Note: those are only overrides on top of relatively reasonable librewolf defaults.
        # If librewolf strays away, I could/should extend this list.
        "webgl.disabled" = false;
        "dom.security.https_only_mode_ever_enabled" = true;
        "browser.policies.runOncePerModification.setDefaultSearchEngine" = "DuckDuckGo";
        "browser.policies.runOncePerModification.extensionsInstall" =
          "[${(ext "ublock-origin")}, ${(ext "bitwarden-password-manager")}]";
      };
  };
}
