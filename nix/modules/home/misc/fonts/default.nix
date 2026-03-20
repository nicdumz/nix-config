{
  pkgs,
  lib,
  config,
  namespace,
  osConfig ? { },
  ...
}:
let
  mkFontOption =
    {
      kind,
      name,
      pkg,
    }:
    {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Family name for ${kind} font profile";
        example = "Fira Code";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkg;
        description = "Package for ${kind} font profile";
        example = "pkgs.fira-code";
      };
      # TODO: find a way to scale this depending on scaling factors.
      size = lib.mkOption {
        type = lib.types.int;
        default = config.${namespace}.scaling.defaultFontSize;
        description = "Size in pixels for ${kind} font profile";
        example = "14";
      };
    };
  cfg = config.fontProfiles;
in
{
  options.${namespace}.scaling.defaultFontSize = lib.mkOption {
    type = lib.types.int;
    default = osConfig.${namespace}.scaling.defaultFontSize or 14;
    description = "Default font size";
  };

  # TODO: move to namespace
  options.fontProfiles = {
    monospace = mkFontOption {
      kind = "monospace";
      name = "CaskaydiaCove Nerd Font";
      pkg = pkgs.nerd-fonts.caskaydia-cove;
    };
    regular = mkFontOption {
      kind = "regular";
      name = "Arimo Nerd Font";
      pkg = pkgs.nerd-fonts.arimo;
    };
  };

  config = {
    fonts.fontconfig.enable = true;
    home.packages = [
      # nit: this could iterate on above cfg somehow
      cfg.monospace.package
      cfg.regular.package
    ];
  };
}
