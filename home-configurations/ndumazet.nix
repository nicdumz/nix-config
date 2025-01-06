{ pkgs, config, ... }:
{
  home.username = "ndumazet";

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
      stkb.rewrap
    ];
    userSettings = {
      "editor.fontSize" = 16;
      "editor.rulers" = [
        80
        100
      ];
      "editor.fontFamily" =
        config.fontProfiles.monospace.name + ", 'Droid Sans Mono', 'monospace', monospace";
      "rewrap.autoWrap.enabled" = true;
      "rewrap.wrappingColumn" = 100;
      "nix.formatterPath" = [
        "nix"
        "fmt"
        "--"
        "--"
      ];
      "nix.serverPath" = "nixd";
      "nix.enableLanguageServer" = true;
      "[nix]" = {
        "editor.formatOnSave" = true;
      };
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
      inherit (config.fontProfiles.monospace) name;
    };
    # https://sw.kovidgoyal.net/kitty/shell-integration/
    # wut wut
    # see also https://nix-community.github.io/home-manager/options.xhtml#opt-programs.kitty.shellIntegration.mode
    shellIntegration.enableFishIntegration = true;
    settings = {
      scrollback_lines = 20000;
      cursor_stop_blinking_after = 0;

      # What follows is my custom nova-colors theme.
      # NOTE: I suspect I'll need the colors in other places, might be worth a separate .nix with
      # better color names.
      cursor = "#7fc1ca";
      cursor_text_color = "#3c4c55";
      background = "#3c4c55";
      foreground = "#c5d4dd";
      #: Black
      color0 = "#3c4c55";
      color8 = "#899ba6";
      #: Red
      color1 = "#f2777a";
      color9 = "#f2c38f";
      #: Green
      color2 = "#99cc99";
      color10 = "#a8ce93";
      #: Yellow
      color3 = "#ffcc66";
      color11 = "#dada93";
      #: Blue
      color4 = "#6699cc";
      color12 = "#83afe5";
      #: Magenta
      color5 = "#cc99cc";
      color13 = "#d18ec2";
      #: Cyan
      color6 = "#66cccc";
      color14 = "#7fc1ca";
      #: White
      color7 = "#dddddd";
      color15 = "#e6eef3";
      # TODO: missing
      # -open_url_modifiers ctrl
      # -remember_window_size  no
      # -initial_window_width  200c
      # -initial_window_height 48c
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
      };
  };
}
