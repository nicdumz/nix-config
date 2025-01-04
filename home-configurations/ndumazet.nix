{ pkgs, self, ... }:
{
  home.username = "ndumazet";
  home.homeDirectory = "/home/ndumazet";

  programs.git = {
    userEmail = "nicdumz.commits@gmail.com";
    userName = "Nicolas Dumazet";
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      asvetliakov.vscode-neovim
      jnoortheen.nix-ide
    ];
    userSettings = {
      "editor.fontSize" = 16;
      "nix.serverPath" = "nixd";
      "nix.enableLanguageServer" = true;
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "nix.serverSettings" = {
        nixd = {
          options = {
            #default = {
            #  expr = "import <nixpkgs> { }";
            #};
            nixos = {
              expr = "(builtins.getFlake \"\${workspaceFolder}\").nixosConfigurations.bistannix.options";
            };
            home-manager = {
              expr = "(builtins.getFlake \"\${workspaceFolder}\").homeConfigurations.\"ndumazet@bistannix\".options";
            };
          };
        };
      };
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      # TODO: this actually depends on display scaling ..
      size = 20;
      name = "Cascadia Code NF";
    };
    # https://sw.kovidgoyal.net/kitty/shell-integration/
    # wut wut
    # see also https://nix-community.github.io/home-manager/options.xhtml#opt-programs.kitty.shellIntegration.mode
    shellIntegration.enableFishIntegration = true;
    settings = {
      scrollback_lines = 20000;
      cursor_stop_blinking_after = 0;
      # missing
      # -open_url_modifiers ctrl
      # -remember_window_size  no
      # -initial_window_width  200c
      # -initial_window_height 48c
    };
    extraConfig = ''
      include $XDG_CONFIG_HOME/kitty/nova-colors.conf
    '';
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
