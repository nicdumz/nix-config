{
  namespace,
  lib,
  ...
}:
{
  snowfallorg.users = {
    ndumazet = {
      create = true;
      admin = true;
      home.config.${namespace} = {
        kitty.enable = true;
        vscode.enable = true;
        librewolf.enable = true;
      };
    };
    giulia = {
      # Do not enable by default, opt-in.
      create = lib.mkDefault false;
      admin = false;
      home.config.${namespace} = {
        chrome.enable = true;
      };
    };
  };
}
