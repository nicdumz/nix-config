{ lib, ... }:
{
  options = {
    nicdumz.embedFlake = lib.mkEnableOption "Whether to embed flake sources.";
    nicdumz.graphical = lib.mkEnableOption "Is this machine running a graphical env.";
  };
}
