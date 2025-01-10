{
  namespace,
  config,
  lib,
  ...
}:
let
  cfg = config.${namespace}.persistence;
in
{
  options.${namespace}.persistence.enable = lib.mkEnableOption "Enable persistence";
  config = lib.mkIf cfg.enable {
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/ssh"
        # I originally only preserved the fish_history file in this directory but
        # this created noise due to
        # https://github.com/fish-shell/fish-shell/issues/10730
        "/root/.local/share/fish"
        "/var/cache"
        "/var/db/sudo"
        "/var/lib"
        "/var/log"
      ];
      files = [
        "/etc/machine-id"
        "/etc/nix/id_rsa"
      ];
    };

    fileSystems."/".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;
  };
}
