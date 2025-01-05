{ pkgs, ... } :
{
  home.username = "giulia";
  home.packages = [
    pkgs.google-chrome
  ];
}
