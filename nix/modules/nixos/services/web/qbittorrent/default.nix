{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.qbittorrent;
in
{
  options.${namespace}.qbittorrent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Qbittorrent: Download stuff.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.qbittorrent = {
      enable = true;
      group = "media";
      webuiPort = 9096;
      torrentingPort = 6882;
      serverConfig = {
        LegalNotice.Accepted = true;
        BitTorrent.Session = {
          DefaultSavePath = "/media/bigslowdata/downloads";
          QueueingSystemEnabled = true;
          IgnoreSlowTorrentsForQueueing = true;
          SlowTorrentsDownloadRate = 40; # kbps
          SlowTorrentsUploadRate = 40; # kbps
          GlobalMaxInactiveSeedingMinutes = 43800;
          GlobalMaxSeedingMinutes = 10080;
          GlobalMaxRatio = 2;
          MaxActiveCheckingTorrents = 2;
          MaxActiveDownloads = 5;
          MaxActiveUploads = 15;
          MaxActiveTorrents = 20;
          MaxConnections = 600;
          MaxUploads = 200;
        };
        Preferences.WebUI = {
          AlternativeUIEnabled = true;
          RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
          AuthSubnetWhitelist = "0.0.0.0/0";
          AuthSubnetWhitelistEnabled = true;
        };
      };
    };
    users.groups.media = { };

    # TODO: maybe could be in the firewall module.
    networking.firewall.interfaces.wan0 = {
      allowedTCPPorts = [ config.services.qbittorrent.torrentingPort ];
      allowedUDPPorts = [ config.services.qbittorrent.torrentingPort ];
    };

    ${namespace} = {
      motd.systemdServices = [ "qbittorrent" ];
      traefik.webservices.qbittorrent.port = config.services.qbittorrent.webuiPort;
    };
  };
}
