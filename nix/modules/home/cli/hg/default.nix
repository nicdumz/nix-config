{ config, ... }:
{
  programs.mercurial = {
    enable = true;
    inherit (config.programs.git) userEmail;
    inherit (config.programs.git) userName;
    extraConfig = {
      ui.editor = "nvim -c 'set ft=hgs'";
      color = {
        # bold green current CL in graph
        "desc.here" = "green bold";
      };
      google-change-tags = {
        "default.markdown" = true;
      };
    };
  };
}
