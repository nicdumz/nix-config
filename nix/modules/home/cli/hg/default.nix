{ config, ... }:
{
  programs.mercurial = {
    enable = true;
    userEmail = config.programs.git.settings.user.email;
    userName = config.programs.git.settings.user.name;
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
