{
  pkgs,
  ...
}:
{
  home.packages = [
    # useful for (shell) color diagnosis.
    pkgs.neofetch
  ];
}
