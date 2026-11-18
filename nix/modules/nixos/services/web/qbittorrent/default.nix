{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.qbittorrent;
  stateDir = lib.removeSuffix "/" config.services.qbittorrent.profileDir;
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
          # SMR pool disks handle torrent random writes badly: stage incomplete files on the NVMe.
          TempPathEnabled = true;
          TempPath = "${stateDir}/incomplete";
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
    # Pinned: dynamic uids/gids are not stable across userborn runs with
    # mutableUsers = false, and this user/group own persisted state.
    users.users.qbittorrent.uid = 900;
    users.groups.media.gid = 895;

    # TODO: maybe could be in the firewall module.
    networking.firewall.interfaces.wan0 = {
      allowedTCPPorts = [ config.services.qbittorrent.torrentingPort ];
      allowedUDPPorts = [ config.services.qbittorrent.torrentingPort ];
    };

    ${namespace} = {
      motd.systemdServices = [ "qbittorrent" ];
      persistence.directories = [
        {
          directory = stateDir;
          inherit (config.services.qbittorrent) user group;
        }
      ];
      traefik.webservices.qbittorrent.port = config.services.qbittorrent.webuiPort;
    };
  };
}
