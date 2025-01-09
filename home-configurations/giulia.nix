{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.username = "giulia";
  home.packages = [
    (lib.mkIf osConfig.nicdumz.graphical pkgs.google-chrome)
  ];
}
