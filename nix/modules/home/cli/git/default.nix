{
  programs.git = {
    enable = true;
    aliases = {
      st = "status";
      ci = "commit";
      glog = "log --graph --decorate --branches=*";
    };
    extraConfig = {
      core.editor = "nvim";
      "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
      # TODO: everything below should be configured per-user.
      github.user = "nicdumz";
    };
    userEmail = "nicdumz.commits@gmail.com";
    userName = "Nicolas Dumazet";
  };
}
