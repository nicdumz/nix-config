{
  pkgs,
  lib,
  config,
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
        default = 12;
        description = "Size in pixels for ${kind} font profile";
        example = "14";
      };
    };
  cfg = config.fontProfiles;
in
{
  options.fontProfiles = {
    monospace = mkFontOption {
      kind = "monospace";
      name = "Cascadia Code NF";
      pkg = pkgs.cascadia-code;
    };
    regular = mkFontOption {
      kind = "regular";
      name = "Cantarell";
      pkg = pkgs.cantarell-fonts;
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
