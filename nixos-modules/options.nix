{ lib, ... }:
{
  options = {
    nicdumz.embedFlake = lib.mkEnableOption "Whether to embed flake sources.";
  };
}
