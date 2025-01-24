{
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  lan = "enp1s0f0";
  wan = "enp1s0f1";
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = lib.${namespace}.mkDiskLayout {
    swapsize = 0;
    # Take no chances and refer to the precise part.
    device = "TODO";
  };

  ${namespace} = {
    persistence.enable = true;
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };
    # TODO: Sounds like networkd might take care of that.
    # corerad = {
    #   enable = true;
    #   inherit lan;
    #   inherit wan;
    # };
    blocky.enable = true;
    prober7.enable = true;
  };

  boot.kernel.sysctl = {
    # source:
    #  https://github.com/mdlayher/homelab/blob/main/nixos/routnerr-3/configuration.nix
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.${wan}.accept_ra" = 2;
    "net.ipv6.conf.${wan}.autoconf" = 1;
  };

  systemd.network = {
    enable = true;

    # TODO: allow hotplug for all
    # NOTE: nftables.enable = true is tempting however interactions with Docker are complicated.

    networks = {
      "10-wan" = {
        matchConfig.Name = wan;
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
        };
        dhcpPrefixDelegationConfig = {
          Token = "::1";
          SubnetId = 0;
        };
        # Never accept ISP DNS or search domains for any DHCP/RA family.
        dhcpV4Config = {
          UseDNS = false;
          UseDomains = false;

          # Don't release IPv4 address on restart/reboots to avoid churn.
          SendRelease = false;
        };
        dhcpV6Config = {
          # init7 gives a /48.
          PrefixDelegationHint = "::/48";

          UseDNS = false;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false;
          UseDomains = false;
        };
        linkConfig.RequiredForOnline = "routable";
      };

      "15-lan" = {
        matchConfig.Name = lan;
        address = [
          # TODO: learn about ULA and see if this makes sense.
          # "fd83:c8db:133a::1/64" # generated ULA
          "192.168.1.0/24"
        ];
        networkConfig = {
          # v4 stuff
          DHCPServer = true; # v4
          IPMasquerade = "ipv4";

          # v6 stuff
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;

          # Allow mDNS to work on the LAN.
          MulticastDNS = true;
        };

        # v4
        dhcpServerConfig = {
          PoolOffset = 50;
          PoolSize = 100;
          EmitDNS = true;
          DNS = "_server_address";
        };
        dhcpServerStaticLeases = [
          # usw-mini
          {
            MACAddress = "74:ac:b9:ab:b7:34";
            Address = "192.168.1.2";
          }
          # unifi-ap-ac-prod
          {
            MACAddress = "f4:92:bf:23:42:c7";
            Address = "192.168.1.3";
          }
          # unifi-cloudkey
          {
            MACAddress = "74:ac:b9:16:73:33";
            Address = "192.168.1.4";
          }
          # jonsnow-admin0
          {
            # this is the admin0 port
            MACAddress = "a8:a1:59:92:8f:9d";
            Address = "192.168.1.5";
          }

          # chromecastgoogletv
          {
            MACAddress = "14:c1:4e:01:b3:21";
            Address = "192.168.1.10";
          }
          # pikvm
          {
            MACAddress = "e4:5f:01:4c:f8:24";
            Address = "192.168.1.11";
          }
          # bistannix
          {
            MACAddress = "f0:2f:74:79:de:79";
            Address = "192.168.1.42";
          }
          # traboule
          {
            MACAddress = "10:e7:c6:34:de:74";
            Address = "192.168.1.43";
          }

          # elgato-keylight
          {
            MACAddress = "3c:6a:9d:14:cd:fd";
            Address = "192.168.1.240";
          }
          # philips-hue
          {
            MACAddress = "00:17:88:6b:d0:9b";
            Address = "192.168.1.241";
          }
          # tahoma-bridge
          {
            MACAddress = "f4:3c:3b:e7:1c:3e";
            Address = "192.168.1.242";
          }
        ];

        # v6
        dhcpPrefixDelegationConfig = {
          Token = "::1";
          SubnetId = 0;
        };
        ipv6SendRAConfig = {
          EmitDNS = true;
          DNS = "_link_local";
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };

  };

  systemd.services.tailscale-transport-layer-offloads = {
    # See https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration.
    description = "Tailscale: better performance for exit nodes";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K ${wan} rx-udp-gro-forwarding on rx-gro-list off";
    };
    wantedBy = [ "default.target" ];
  };

  environment.systemPackages = with pkgs; [
    ethtool
  ];

  # TODO: backup cron
  # 0 4 * * * rclone --drive-shared-with-me copy /media/bigslowdata/paperless/media/documents/originals/ drive-remote:jonsnow-backups/paperless-backups

  fileSystems.bigdata = {
    mountPoint = "/media/bigslowdata";
    fsType = "ext4";
    device = "/dev/mapper/bigslowdata_vg-bigslowdata_lv";
    options = [
      "defaults"
      "noatime"
    ];
  };
}
