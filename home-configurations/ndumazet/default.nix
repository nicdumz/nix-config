{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./kitty.nix
    ./tmux.nix
    ./vscode.nix
  ];

  home.username = "ndumazet";

  programs.git = {
    userEmail = "nicdumz.commits@gmail.com";
    userName = "Nicolas Dumazet";
    extraConfig = {
      github.user = "nicdumz";
    };
  };

  # NOTE: enabled for me but consider (?) if useful for root. I initially assume that developing as
  # root is a bad habit [...].
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  # TODO: lacks configuration
  programs.irssi.enable = true;
  programs.hexchat.enable = true;

  home.packages = [
    # useful for (shell) color diagnosis.
    pkgs.neofetch
  ];

  programs.mercurial = {
    enable = true;
    inherit (config.programs.git) userEmail;
    inherit (config.programs.git) userName;
    extraConfig = {
      ui.editor = "nvim -c 'set ft=hgs'";
      color = {
        # bold green current CL in graph
        "desc.here" = "green bold";
      };
      google-change-tags = {
        "default.markdown" = true;
      };
    };
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
        "font.name.monospace.x-western" = config.fontProfiles.monospace.name;
      };
  };
}
