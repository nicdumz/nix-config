{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
let
  lan = "lan0";
  wan = "wan0";

  ethLink =
    name:
    (mac: {
      matchConfig = {
        Type = "ether";
        MACAddress = mac;
      };
      linkConfig = {
        Name = name;
        RxBufferSize = 8196;
        TxBufferSize = 8196;
      };
    });
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
    traefik.enable = true;
    glance.enable = true;
    grocy.enable = true;
    motd = {
      enable = true;
      networkInterfaces = [
        lan
        wan
      ];
    };
    rebootRequiredCheck.enable = true;
    # observability stuff
    loki.enable = true;
    vector.enable = true;
    grafana.enable = true;
    prometheus.enable = true;
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

  networking = {
    useDHCP = false; # manually configure below via networkd

    # Docker firewall rules take over the forwarding chain and redirect all to DOCKER-USER.
    # Make sure that forwarding still works as intended.
    # There's a good discussion on https://github.com/NixOS/nixpkgs/issues/111852 although people
    # are generally confused.
    firewall.extraCommands = ''
      ip46tables -N DOCKER-USER || true
      ip46tables -N DOCKER-ISOLATION-STAGE-1 || true
      ip46tables -N ts-forward || true

      ip46tables -F FORWARD
      ip46tables -P FORWARD DROP
      ip46tables -A FORWARD -j DOCKER-USER
      ip46tables -A FORWARD -j DOCKER-ISOLATION-STAGE-1

      # DOCKER-USER is the chain that Docker lets us control.
      ip46tables -F DOCKER-USER
      # Tailscale rules first
      ip46tables -A DOCKER-USER -j ts-forward
      # Forward already open.
      ip46tables -A DOCKER-USER -m state --state RELATED,ESTABLISHED -j ACCEPT

      ## Am a bit confused as to why those rules are required. Technically Docker should port
      ## forward to the local host which should remove routing/fw needs; this needs more work.
      # Wan to Deluge, qBittorrent
      ip46tables -A DOCKER-USER -i ${wan} -o docker-bridge -p udp -m udp --dport 6881 -j ACCEPT
      ip46tables -A DOCKER-USER -i ${wan} -o docker-bridge -p tcp -m tcp --dport 6881 -j ACCEPT
      ip46tables -A DOCKER-USER -i ${wan} -o docker-bridge -p udp -m udp --dport 51413 -j ACCEPT
      ip46tables -A DOCKER-USER -i ${wan} -o docker-bridge -p tcp -m tcp --dport 51413 -j ACCEPT

      # Anything !wan can open to the outside.
      ip46tables -A DOCKER-USER ! -i ${wan} -o ${wan} -j ACCEPT
      # cross containers (different phys ifaces)
      ip46tables -A DOCKER-USER -i docker-bridge -o docker-bridge -j ACCEPT

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

    links = {
      "10-wan" = ethLink wan "00:1b:21:c3:4a:f6";
      "15-lan" = ethLink lan "00:1b:21:c3:4a:f4";
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
        # Never accept ISP DNS or search domains for any DHCP/RA family.
        dhcpV4Config = {
          UseDNS = false;
          UseDomains = false;
          UseHostname = false;

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
          # TODO: can i teach v4 server to only bind on the local address instead of 0.0.0.0?
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
