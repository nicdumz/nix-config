{ lib, namespace, ... }:
{
  options.${namespace} = {
    graphical = lib.mkEnableOption "Is this machine running a graphical env.";
  };
}
