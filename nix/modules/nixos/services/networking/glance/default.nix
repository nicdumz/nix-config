{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.glance;
  capitalize =
    s:
    let
      n = builtins.stringLength s;
    in
    (lib.strings.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (n - 1) s);

  # TODO: distribute config to modules.
  groups = {
    Media = {
      order = 1;
      sites = [
        "jellyfin"
        {
          name = "jellyseerr";
          icon = "/assets/jellyseerr.png";
        }
        {
          name = "sonarr";
          suffix = "(Series)";
        }
        {
          name = "radarr";
          suffix = "(Movies)";
        }
      ];
    };
    Food = {
      order = 2;
      sites = [
        {
          name = "mealie";
          # https://github.com/simple-icons/simple-icons/issues/12673
          icon = "/assets/mealie.svg";
        }
      ];
    };
    Home = {
      order = 3;
      sites = [
        {
          name = "paperless";
          icon = "paperlessngx";
        }
        "homeassistant"
        {
          name = "traefik";
          icon = "traefikproxy";
        }
      ];
    };
    Downloads = {
      order = 4;
      sites = [
        {
          name = "bazarr";
          icon = "/assets/bazarr.png";
        }
        "deluge"
        "qbittorrent"
      ];
    };
    Observability = {
      order = 5;
      sites = [
        "grafana"
        {
          name = "alertmanager";
          icon = "prometheus";
        }
        {
          name = "blackbox";
          icon = "prometheus";
        }
        "prometheus"
        "portainer" # maybe this will / should go.
      ];
    };
  };
  sortedGroupValuePairList = lib.lists.sort (a: b: a.value.order < b.value.order) (
    lib.attrsets.mapAttrsToList lib.attrsets.nameValuePair groups
  );
  mkMonitorGroup = title: v: {
    type = "monitor";
    cache = "1m";
    inherit title;
    sites = builtins.map (
      s:
      let
        name = if builtins.isString s then s else s.name;
        icon = if builtins.isString s then s else (s.icon or name);
        title_suffix = if s ? "suffix" then " ${s.suffix}" else "";
      in
      {
        title = (capitalize name) + title_suffix;
        url = "https://${name}.home.nicdumz.fr";
        icon = if lib.strings.hasPrefix "/" icon then icon else "si:${icon}";
      }
    ) v.sites;
  };
  column = {
    size = "full";
    widgets = builtins.map (x: mkMonitorGroup x.name x.value) sortedGroupValuePairList;
  };
  glancePage = {
    name = "Lethargy services";
    width = "slim";
    hide-desktop-navigation = true;
    columns = [ column ];
  };

  themes = {
    catppuccin-mocha = {
      background-color = "240 21 15";
      contrast-multiplier = 1.2;
      primary-color = "217 92 83";
      positive-color = "115 54 76";
      negative-color = "347 70 65";
    };
    teal-city = {
      background-color = "225 14 15";
      primary-color = "157 47 65";
      contrast-multiplier = 1.1;
    };
  };
in
{
  options.${namespace}.glance = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ...";
    };
  };
  config = lib.mkIf cfg.enable {
    services.glance = {
      enable = true;
      settings = {
        server.port = 8081;
        server.assets-path = ./icons;
        pages = [ glancePage ];
        theme = themes.catppuccin-mocha // {
          custom-css-file = "/assets/custom.css";
        };
        branding.hide-footer = true;
      };
    };
  };
}
