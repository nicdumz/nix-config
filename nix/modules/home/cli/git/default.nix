{ config, ... }:
{
  programs = {
    git = {
      enable = true;
      settings = {
        core.editor = "nvim";
        core.askPass = ""; # needs to be empty to use terminal for ask pass
        "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
        aliases = {
          st = "status";
          ci = "commit";
          glog = "log --graph --decorate --branches=*";
        };
        # TODO: everything below should be configured per-user.
        github.user = "nicdumz";
        user.email = "nicdumz.commits@gmail.com";
        user.name = "Nicolas Dumazet";
      };
    };

    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
    jujutsu = {
      enable = true;
      settings = {
        user = {
          inherit (config.programs.git.settings.user) email;
          inherit (config.programs.git.settings.user) name;
        };
        ui = {
          default-command = "log";
          pager = ":builtin";
        };
      };
    };
  };
}
