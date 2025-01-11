{
  config,
  osConfig,
  lib,
  namespace,
  ...
}:
{
  programs.kitty = lib.optionalAttrs osConfig.${namespace}.graphical {
    enable = true;
    font = {
      # TODO: this actually depends on display scaling ..
      inherit (config.fontProfiles.monospace) size;
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
}
