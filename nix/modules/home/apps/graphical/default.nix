{
  config,
  inputs,
  osConfig ? { },
  lib,
  namespace,
  ...
}:
let
  # Approximation
  # TODO: put somewhere else
  laptop = osConfig.networking.networkmanager.enable or false;
in
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
    extraConfig = builtins.readFile ./hyprland.conf;
  };
  services = {
    hyprpolkitagent.enable = true;

    # auto-lock
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
          before_sleep_cmd = "hyprlock";
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

    hyprpaper = {
      enable = true;
      settings = {
        splash = false;
        preload = [
          "${inputs.self.outPath}/assets/wallpapers/train-sideview.png"
        ];
        wallpaper = [
          ",${inputs.self.outPath}/assets/wallpapers/train-sideview.png"
        ];
      };
    };
  };

  programs = {
    # top bar & notifications
    hyprpanel =
      let
        themeDirectory = "${config.programs.hyprpanel.package}/share/themes";
        currentTheme = "catppuccin_mocha";
        raw = lib.importJSON "${themeDirectory}/${currentTheme}.json";
        selectedTheme = raw.theme or raw;

        # We need to turn the theme json into a nested attribute set. Otherwise we
        # end up with an incorrect configuration that looks like:
        # theme: {theme.bar.transparent: "value", theme.foo.bar: "another value"}
        # when what we really want is: theme: {bar: ..., buttons: ...}
        # ----
        # turn "foo.bar.baz" and value into { foo = { bar = { baz = value; }; }; }
        nestAttr = path: value: lib.attrsets.setAttrByPath (lib.splitString "." path) value;

        # merge a flat attrset into nested
        unflatten =
          flat:
          lib.foldlAttrs (
            acc: k: v:
            lib.recursiveUpdate acc (nestAttr k v)
          ) { } flat;

        themeAttrs = unflatten selectedTheme;
        baseTheme = themeAttrs.theme;

        power = {
          sleep = "systemctl suspend";
          logout = "hyprctl dispatch exit";
          reboot = "systemctl reboot";
          shutdown = "systemctl poweroff";
          confirmation = false;
        };
      in
      {
        enable = true;
        settings = {
          theme = baseTheme // {
            font = {
              name = "CaskaydiaCove NF";
              size = "16px";
            };
            bar.buttons.windowtitle.spacing = "1em";
          };
          menus = {
            clock = {
              time.military = true;
              weather = {
                unit = "metric";
                location = "Zurich, Switzerland";
                key = osConfig.sops.templates.weather_api_key.path;
              };
            };
            dashboard.shortcuts.left = {
              shortcut1 = {
                icon = "";
                command = "google-chrome";
                tooltip = "Chrome";
              };
              shortcut2 = {
                icon = "";
                command = "codium";
                tooltip = "VSCodium";
              };
              shortcut3 = {
                icon = "󰄛";
                command = "kitty";
                tooltip = "Terminal";
              };
            };
            dashboard.powermenu = power;
            inherit power;
          };
          bar = {
            clock.format = "%a %b %d  %H:%M:%S";
            notifications.show_total = true;
            launcher.icon = "󰍜";
            layouts = {
              "*" = {
                left = [
                  "dashboard"
                  "workspaces"
                ];
                middle = [
                  "windowtitle"
                ];
                right = builtins.concatLists [
                  [
                    "media"
                    "volume"
                  ]
                  (lib.optionals laptop [
                    "network"
                    "bluetooth"
                    "battery"
                  ])
                  [
                    "hypridle"
                    # Note: using gammasetp instead
                    # "hyprsunset"
                    "systray"
                    "clock"
                    "notifications"
                  ]
                ];
              };
            };
            systray.customIcons = {
              gammastep = {
                icon = "󱩌";
              };
            };
            windowtitle.title_map = [
              [
                "gjs"
                ""
                "Hyprpanel Settings"
              ]
              [
                "codium"
                ""
                "Codium"
              ]
            ];
          };
          wallpaper.enable = false;
          scalingPriority = "hyprland";
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
        display-drun = " Apps";
        display-run = " Run";
        display-filebrowser = " File";
      };
      # This theme is adding to the catppuccin mocha theme, mostly rounding.
      theme =
        let
          # Use `mkLiteral` for string-like values that should show without
          # quotes, e.g.:
          # {
          #   foo = "abc"; => foo: "abc";
          #   bar = mkLiteral "abc"; => bar: abc;
          # };
          inherit (config.lib.formats.rasi) mkLiteral;
        in
        {
          window = {
            # width:            600px;
            border = mkLiteral "2px";
            border-color = mkLiteral "@blue"; # Mocha accent color
            border-radius = mkLiteral "12px"; # Matches standard HyprPanel rounding
            # background-color = mkLiteral "@bg-col";
          };
          element = {
            padding = mkLiteral "8px";
            border-radius = mkLiteral "8px"; # Rounded selection highlight
            margin = mkLiteral "2px 5px";
          };
          "element selected.normal" = {
            # force maroon for selected color.
            background-color = mkLiteral "@maroon";
          };
        };
    };

  };
  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
