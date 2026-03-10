{
  config,
  osConfig ? { },
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (osConfig.${namespace}.graphical or false) {
  # TODO: modularize
  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland
    systemd = {
      variables = [ "--all" ];
    };
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
    };
    extraConfig = ''
      exec-once = $terminal
      # This lets me add non-hermetic settings and reloading before integrating
      # them into this configuration.
      source = ~/.config/hypr/hyprland/*
    '';
  };
  services = {
    # notifications
    swaync.enable = true;
    hyprpolkitagent.enable = true;
    network-manager-applet.enable = true;

    # auto-lock
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };

        listener = [
          {
            timeout = 900;
            on-timeout = "hyprlock";
          }
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    # screen dimming / color
    gammastep = {
      enable = true;
      tray = true;
      # Zurich-ish
      latitude = "47.37";
      longitude = "8.53";
      settings.general.adjustment-method = "wayland";
    };
  };

  programs = {
    # top bar
    waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          # layer = "top";
          # position = "top";
          # height = 30;
          modules-left = [
            "hyprland/workspaces"
            "hyprland/submap"
          ];
          modules-center = [ "hyprland/window" ];
          modules-right = [
            "mpd"
            "idle_inhibitor"
            "wireplumber"
            "network"
            "cpu"
            "memory"
            "temperature"
            "battery"
            "clock"
            "tray"
            "custom/power"
          ];
          tray.spacing = 20;

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
            sort-by-number = true;
            show-special = true;
            special-visible-only = true;
            format-icons = {
              active = "";
              default = "";
            };
          };
          clock = {
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format = "{:%Y-%m-%d %H:%M}";
            calendar.on-scroll = 1;
            actions.on-scroll-up = "shift_up";
            actions.on-scroll-down = "shift_down";
          };
          cpu = {
            format = "{usage}% ";
            tooltip = false;
          };
          memory.format = "{}% ";
          "custom/power" = {
            format = "⏻ ";
            tooltip = false;
            on-click = "wlogout";
          };
          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} 󰈀";
            tooltip-format = "{ifname} via {gwaddr} 󰈀";
            format-linked = "{ifname} (No IP) 󰈀";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };
        };
      };
    };

    # run menu
    rofi = {
      enable = true;
      terminal = "kitty";
      extraConfig = {
        modi = "drun,filebrowser,run";
        show-icons = true;
        icon-theme = "Papirus";
        location = 0;
        # font = "JetBrainsMono Nerd Font Mono 12";
        drun-display-format = "{icon} {name}";
        display-drun = " Apps";
        display-run = " Run";
        display-filebrowser = " File";
      };
    };

    wlogout = {
      enable = true;
      layout = [
        {
          label = "shutdown";
          action = "sleep 1; systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          "label" = "reboot";
          "action" = "sleep 1; systemctl reboot";
          "text" = "Reboot";
          "keybind" = "r";
        }
        {
          "label" = "logout";
          "action" = "sleep 1; hyprctl dispatch exit";
          "text" = "Exit";
          "keybind" = "e";
        }
        {
          "label" = "suspend";
          "action" = "sleep 1; systemctl suspend";
          "text" = "Suspend";
          "keybind" = "u";
        }
        {
          "label" = "lock";
          "action" = "sleep 1; hyprlock";
          "text" = "Lock";
          "keybind" = "l";
        }
        {
          "label" = "hibernate";
          "action" = "sleep 1; systemctl hibernate";
          "text" = "Hibernate";
          "keybind" = "h";
        }
      ];
    };
  };
  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
