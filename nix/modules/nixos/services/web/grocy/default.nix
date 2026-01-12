# Note: I'm generally not super thrilled about grocy:
#  - Anything written in PHP makes me just sad...
#  - the module forcibly enables nginx
# But it's the 'best' shovel-ready product for now.
{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.grocy;
in
{
  options.${namespace}.grocy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Inventory management for food stuff.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8083;
    };
  };
  config =
    let
      tld = "grocy.home.nicdumz.fr"; # TLD that nginx vhost will use.
    in
    lib.mkIf cfg.enable {
      services.grocy = {
        enable = true;
        nginx.enableSSL = false;
        hostName = tld;
        settings.currency = "CHF";
        settings.calendar.firstDayOfWeek = 1;
      };

      environment.etc."grocy/config.php".text = lib.mkAfter ''
        // Disable most features -- don't need them.
        Setting('FEATURE_FLAG_SHOPPINGLIST', false);
        Setting('FEATURE_FLAG_RECIPES', false);
        Setting('FEATURE_FLAG_CHORES', false);
        Setting('FEATURE_FLAG_TASKS', false);
        Setting('FEATURE_FLAG_BATTERIES', false);
        Setting('FEATURE_FLAG_EQUIPMENT', false);
        // However I want to print things :)
        Setting('FEATURE_FLAG_LABEL_PRINTER', true);
        // Datamatrix instead of Code128
        Setting('GROCYCODE_TYPE', '2D');
      '';

      services.nginx.virtualHosts.${tld} = {
        listen = [
          {
            addr = "127.0.0.1";
            inherit (cfg) port;
          }
        ];
      };

      # TODO: upstream
      systemd.services.grocy.unitConfig.RequiresMountsFor = [ config.services.grocy.dataDir ];
      ${namespace} = {
        motd.systemdServices = [ "grocy" ];
        persistence.directories = [
          {
            directory = config.services.grocy.dataDir;
            user = config.users.users.grocy.name;
            inherit (config.users.users.grocy) group;
          }
        ];
        traefik.webservices.grocy.port = cfg.port;
      };
    };
}
