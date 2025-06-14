{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    focusEvents = true;
    historyLimit = 262144;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    sensibleOnTop = true;
    shell = "${pkgs.fish}/bin/fish";
    shortcut = "a";
    terminal = "screen-256color";
    extraConfig = ''
      # Addicted since the byobu era
      unbind-key -n F3
      unbind-key -n F4
      unbind-key -n F7
      bind-key -n F3 previous-window
      bind-key -n F4 next-window
      bind-key -n F7 copy-mode

      # Use clipboard from kitty
      set -s set-clipboard on

      setw -g automatic-rename on
      setw -g xterm-keys on
      # automatically renumber window numbers on closing a pane (needs tmux >= 1.7)
      set -g renumber-windows on
      set -g focus-events on
      set -g mouse on

      # light blue
      set -g @tmux_power_theme 'color12'
    '';
    plugins = with pkgs; [
      tmuxPlugins.power-theme
    ];
  };
}
