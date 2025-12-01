{
  config,
  lib,
  namespace,
  osConfig ? { },
  ...
}:
let
  cfg = config.${namespace}.kitty;
in
{
  options.${namespace}.kitty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable kitty Terminal for this user.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = lib.optionalAttrs (osConfig.${namespace}.graphical or false) {
      enable = true;
      font = {
        # TODO: this actually depends on display scaling ..
        inherit (config.fontProfiles.monospace) size;
        inherit (config.fontProfiles.monospace) name;
      };
      themeFile = "Catppuccin-Mocha";
      # https://sw.kovidgoyal.net/kitty/shell-integration/
      # wut wut
      # see also https://nix-community.github.io/home-manager/options.xhtml#opt-programs.kitty.shellIntegration.mode
      shellIntegration.enableFishIntegration = true;
      settings = {
        scrollback_lines = 20000;
        cursor_stop_blinking_after = 0;

        # TODO: 25.11 this otherwise breaks in Wayland why :-S
        linux_display_server = "x11";

        # TODO: missing
        # -open_url_modifiers ctrl
        # -remember_window_size  no
        # -initial_window_width  200c
        # -initial_window_height 48c

        # Those settings are recommended by https://github.com/catppuccin/kitty
        tab_bar_min_tabs = 1;
        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
      };
    };
  };
}
