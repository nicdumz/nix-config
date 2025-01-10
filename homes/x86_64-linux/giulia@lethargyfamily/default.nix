{
  pkgs,
  lib,
  osConfig,
  namespace,
  ...
}:
{
  # home.username = "giulia";
  home.packages = [
    (lib.mkIf osConfig.${namespace}.graphical pkgs.google-chrome)
  ];
}
