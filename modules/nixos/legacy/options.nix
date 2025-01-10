{ lib, namespace, ... }:
{
  options.${namespace} = {
    embedFlake = lib.mkEnableOption "Whether to embed flake sources.";
    graphical = lib.mkEnableOption "Is this machine running a graphical env.";
  };
}
