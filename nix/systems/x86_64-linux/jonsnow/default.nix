{
  config,
  inputs,
  lib,
  namespace,
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
    device = "/dev/disk/by-id/nvme-KINGSTON_SKC2500M8500G_50026B76853C3655";
  };

  ${namespace} = {
    persistence.enable = true;
    tailscale = {
      enable = true;
      exitNode.wanInterface = wan;
    };
    blocky.enable = true;
    prober7.enable = true;
    firewall = {
      interface = lan;
      # DHCP server.
      udp = [ 67 ];
    };
    docker.enable = true;
    motd = {
      enable = true;
      networkInterfaces = [
        lan
        wan
      ];
    };
    rebootRequiredCheck.enable = true;
  };

  # TODO?
  #RxBufferSize = 4096;
  #TxBufferSize = 4096;
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

  networking = {
    useDHCP = false; # manually configure below via networkd

    # Docker firewall rules take over the forwarding chain and redirect all to DOCKER-USER.
    # Make sure that forwarding still works as intended.
    # There's a good discussion on https://github.com/NixOS/nixpkgs/issues/111852 although people
    # are generally confused.
    firewall.extraCommands = ''
      ip46tables -N DOCKER-USER || true
      ip46tables -F DOCKER-USER
      ip46tables -A DOCKER-USER -i ${lan} -o ${wan} -j ACCEPT
      ip46tables -A DOCKER-USER -i ${wan} -o ${lan} -m state --state RELATED,ESTABLISHED -j ACCEPT
      ip46tables -A DOCKER-USER -i ${wan} -j DROP
      ip46tables -A DOCKER-USER -j RETURN
    '';
  };

  systemd.network = {
    enable = true;

    config.networkConfig.SpeedMeter = true;

    # TODO: allow hotplug for all
    # NOTE: nftables.enable = true is tempting however interactions with Docker are complicated.

    wait-online = {
      extraArgs = [
        "--ipv4"
        "--ipv6"
        "--interface=${wan}"
        "--interface=${lan}"
      ];
      timeout = 20; # seconds
    };

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
          UplinkInterface = ":self";
          SubnetId = 0;
          Announce = "no";
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
          "${config.${namespace}.myipv4}/24"
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
          EmitRouter = true;
          DNS = "_server_address";
        };
        dhcpServerStaticLeases =
          let
            toLease = _n: v: {
              MACAddress = v.mac;
              Address = v.ip;
            };
            filterOutSelf = lib.attrsets.filterAttrs (n: _v: n != config.networking.hostName);
          in
          lib.attrsets.mapAttrsToList toLease (filterOutSelf config.${namespace}.networkmap);

        # v6
        dhcpPrefixDelegationConfig = {
          SubnetId = 1;
        };
        ipv6SendRAConfig = {
          EmitDNS = true;
          DNS = "_link_local";
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };

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
