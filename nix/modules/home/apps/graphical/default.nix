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
  services.swaync.enable = true;
  services.hyprpolkitagent.enable = true;

  programs = {
    ashell.enable = true;
    ashell.systemd.enable = true;
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
      theme =
        let
          inherit (config.lib.formats.rasi) mkLiteral;
        in
        {
          "*" = {
            bg = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base00}");
            bg-alt = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base09}");
            foreground = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base01}");
            selected = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base08}");
            active = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base0B}");
            text-selected = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base00}");
            text-color = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base05}");
            border-color = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base0F}");
            urgent = lib.mkForce (mkLiteral "#${config.lib.stylix.colors.base0E}");
          };
          "window" = {
            width = mkLiteral "50%";
            transparency = "real";
            orientation = mkLiteral "vertical";
            cursor = mkLiteral "default";
            spacing = mkLiteral "0px";
            border = mkLiteral "2px";
            border-color = "@border-color";
            border-radius = mkLiteral "20px";
            background-color = lib.mkForce (mkLiteral "@bg");
          };
          "mainbox" = {
            padding = mkLiteral "15px";
            enabled = true;
            orientation = mkLiteral "vertical";
            children = map mkLiteral [
              "inputbar"
              "listbox"
            ];
            background-color = lib.mkForce (mkLiteral "transparent");
          };
          "inputbar" = {
            enabled = true;
            padding = mkLiteral "10px 10px 200px 10px";
            margin = mkLiteral "10px";
            background-color = lib.mkForce (mkLiteral "transparent");
            border-radius = "25px";
            orientation = mkLiteral "horizontal";
            children = map mkLiteral [
              "entry"
              "dummy"
              "mode-switcher"
            ];
            background-image = mkLiteral ''url("${config.${namespace}.wallpaper.path}", width)'';
          };
          "entry" = {
            enabled = true;
            expand = false;
            width = mkLiteral "20%";
            padding = mkLiteral "10px";
            border-radius = mkLiteral "12px";
            background-color = lib.mkForce (mkLiteral "@selected");
            text-color = lib.mkForce (mkLiteral "@text-selected");
            cursor = mkLiteral "text";
            placeholder = "🖥️ Search ";
            placeholder-color = mkLiteral "inherit";
          };
          "listbox" = {
            spacing = mkLiteral "10px";
            padding = mkLiteral "10px";
            background-color = lib.mkForce (mkLiteral "transparent");
            orientation = mkLiteral "vertical";
            children = map mkLiteral [
              "message"
              "listview"
            ];
          };
          "listview" = {
            enabled = true;
            columns = 2;
            lines = 6;
            cycle = true;
            dynamic = true;
            scrollbar = false;
            layout = mkLiteral "vertical";
            reverse = false;
            fixed-height = false;
            fixed-columns = true;
            spacing = mkLiteral "10px";
            background-color = lib.mkForce (mkLiteral "transparent");
            border = mkLiteral "0px";
          };
          "dummy" = {
            expand = true;
            background-color = lib.mkForce (mkLiteral "transparent");
          };
          "mode-switcher" = {
            enabled = true;
            spacing = mkLiteral "10px";
            background-color = lib.mkForce (mkLiteral "transparent");
          };
          "button" = {
            width = mkLiteral "5%";
            padding = mkLiteral "12px";
            border-radius = mkLiteral "12px";
            background-color = lib.mkForce (mkLiteral "@text-selected");
            text-color = lib.mkForce (mkLiteral "@text-color");
            cursor = mkLiteral "pointer";
          };
          "button selected" = {
            background-color = lib.mkForce (mkLiteral "@selected");
            text-color = lib.mkForce (mkLiteral "@text-selected");
          };
          "scrollbar" = {
            width = mkLiteral "4px";
            border = 0;
            handle-color = lib.mkForce (mkLiteral "@border-color");
            handle-width = mkLiteral "8px";
            padding = 0;
          };
          "element" = {
            enabled = true;
            spacing = mkLiteral "10px";
            padding = mkLiteral "10px";
            border-radius = mkLiteral "12px";
            background-color = lib.mkForce (mkLiteral "transparent");
            cursor = mkLiteral "pointer";
          };
          "element normal.normal" = {
            background-color = lib.mkForce (mkLiteral "inherit");
            text-color = lib.mkForce (mkLiteral "inherit");
          };
          "element normal.urgent" = {
            background-color = lib.mkForce (mkLiteral "@urgent");
            text-color = lib.mkForce (mkLiteral "@foreground");
          };
          "element normal.active" = {
            background-color = lib.mkForce (mkLiteral "@active");
            text-color = lib.mkForce (mkLiteral "@foreground");
          };
          "element selected.normal" = {
            background-color = lib.mkForce (mkLiteral "@selected");
            text-color = lib.mkForce (mkLiteral "@text-selected");
          };
          "element selected.urgent" = {
            background-color = lib.mkForce (mkLiteral "@urgent");
            text-color = lib.mkForce (mkLiteral "@text-selected");
          };
          "element selected.active" = {
            background-color = lib.mkForce (mkLiteral "@urgent");
            text-color = lib.mkForce (mkLiteral "@text-selected");
          };
          "element alternate.normal" = {
            background-color = lib.mkForce (mkLiteral "transparent");
            text-color = lib.mkForce (mkLiteral "inherit");
          };
          "element alternate.urgent" = {
            background-color = lib.mkForce (mkLiteral "transparent");
            text-color = lib.mkForce (mkLiteral "inherit");
          };
          "element alternate.active" = {
            background-color = lib.mkForce (mkLiteral "transparent");
            text-color = lib.mkForce (mkLiteral "inherit");
          };
          "element-icon" = {
            background-color = lib.mkForce (mkLiteral "transparent");
            text-color = lib.mkForce (mkLiteral "inherit");
            size = mkLiteral "36px";
            cursor = mkLiteral "inherit";
          };
          "element-text" = {
            background-color = lib.mkForce (mkLiteral "transparent");
            font = "${config.fontProfiles.monospace.name} 12";
            text-color = lib.mkForce (mkLiteral "inherit");
            cursor = mkLiteral "inherit";
            vertical-align = mkLiteral "0.5";
            horizontal-align = mkLiteral "0.0";
          };
          "message" = {
            background-color = lib.mkForce (mkLiteral "transparent");
            border = mkLiteral "0px";
          };
          "textbox" = {
            padding = mkLiteral "12px";
            border-radius = mkLiteral "10px";
            background-color = lib.mkForce (mkLiteral "@bg-alt");
            text-color = lib.mkForce (mkLiteral "@bg");
            vertical-align = mkLiteral "0.5";
            horizontal-align = mkLiteral "0.0";
          };
          "error-message" = {
            padding = mkLiteral "12px";
            border-radius = mkLiteral "20px";
            background-color = lib.mkForce (mkLiteral "@bg-alt");
            text-color = lib.mkForce (mkLiteral "@bg");
          };
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
      style = ''
        * {
          font-family: "${config.fontProfiles.monospace.name}";
        	background-image: none;
        	transition: 20ms;
        }
        window {
        	background-color: rgba(12, 12, 12, 0.1);
        }
        button {
        	color: #${config.lib.stylix.colors.base05};
          font-size:20px;
          background-repeat: no-repeat;
        	background-position: center;
        	background-size: 25%;
        	border-style: solid;
        	background-color: rgba(12, 12, 12, 0.3);
        	border: 3px solid #${config.lib.stylix.colors.base05};
          box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
        }
        button:focus,
        button:active,
        button:hover {
          color: #${config.lib.stylix.colors.base0B};
          background-color: rgba(12, 12, 12, 0.5);
          border: 3px solid #${config.lib.stylix.colors.base0B};
        }
        #lock {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
        	margin: 10px;
        	border-radius: 20px;
        }

        #logout {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
        	margin: 10px;
        	border-radius: 20px;
        }

        #suspend {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
        	margin: 10px;
        	border-radius: 20px;
        }

        #hibernate {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
        	margin: 10px;
        	border-radius: 20px;
        }

        #shutdown {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
        	margin: 10px;
        	border-radius: 20px;
        }

        #reboot {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
        	margin: 10px;
        	border-radius: 20px;
        }
      '';
    };
  };
  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
