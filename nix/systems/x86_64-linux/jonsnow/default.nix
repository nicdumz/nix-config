{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  lan = "lan0";
  wan = "wan0";
  # IoT VLAN (802.1Q tag 20) on the same physical port as lan0.
  iot = "iot0";
  iotAddress = "192.168.20.1";
  networkmap = config.${namespace}.networkmap;

  # Static DHCP leases for the networkmap entries living in the given subnet.
  staticLeasesIn =
    subnetPrefix:
    lib.attrsets.mapAttrsToList
      (_n: v: {
        MACAddress = v.mac;
        Address = v.ip;
      })
      (
        lib.attrsets.filterAttrs (
          n: v: n != config.networking.hostName && lib.hasPrefix subnetPrefix v.ip
        ) networkmap
      );

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
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    # Adding the following to trying to make QSV work, but:
    # TODO: only VAAPI seems to work for now
    libvdpau-va-gl
    # CPU is gen 11th and requires -legacy1
    intel-compute-runtime-legacy1
    vaapi-intel-hybrid
  ];

  ${namespace} = {
    device.type = "server";
    persistence.enable = true;
    myipv6 = "fd83:c8db:133a::1";
    blocky.enable = true;
    prober7.enable = true;
    firewall = {
      interface = lan;
      # DHCP server, mDNS (avahi reflector).
      udp = [
        67
        5353
      ];
    };
    homeassistant.enable = true;
    traefik.enable = true;
    glance.enable = true;
    grocy.enable = true;
    mealie.enable = true;
    paperless.enable = true;
    qbittorrent.enable = true;
    bazarr.enable = true;
    radarr.enable = true;
    sonarr.enable = true;
    prowlarr.enable = true;
    jellyseerr.enable = true;
    plex.enable = true;
    motd = {
      enable = true;
      networkInterfaces = [
        lan
        wan
      ];
    };
    rebootRequiredCheck.enable = true;
    victorialogs.enable = true;
    # 26.05 introduces a breaking change (need to reencrypt DB) and for now i cant be bothered.
    # grafana.enable = true;
    prometheus.enable = true;
    pocketid.enable = true;
    pangolin.enable = true;
  };

  boot.kernel.sysctl = {
    # Master switches: networkd's per-interface Forwarding= isn't enough,
    # the kernel also gates forwarding on these global switches.
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    useDHCP = false; # manually configure below via networkd
    nftables.enable = true;
    useNetworkd = true;

    # Masquerade IPv4 towards the internet only: traffic between lan0 and iot0 keeps its real
    # source address. Also accepts forwarding from both internal interfaces to wan0.
    nat = {
      enable = true;
      externalInterface = wan;
      internalInterfaces = [
        lan
        iot
      ];
    };

    firewall = {
      filterForward = true;
      # IoT -> trusted LAN is not listed: IoT devices only get replies to connections opened
      # from the trusted side (established/related), e.g. casting from a phone.
      extraForwardRules = ''
        iifname "${lan}" oifname "${lan}" accept
        iifname "${lan}" oifname "${iot}" accept
      '';

      # IoT devices may only use jonsnow for DHCP, DNS (blocky) and mDNS reflection...
      interfaces.${iot} = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [
          53
          67
          5353
        ];
      };
      # ...and the TV for Plex.
      extraInputRules = ''
        iifname "${iot}" ether saddr ${networkmap.samsung-tv.mac} tcp dport 32400 accept comment "Samsung TV -> Plex"
      '';
    };
  };

  # Reflect mDNS between the trusted LAN and the IoT VLAN so phones/laptops discover
  # Cast/AirPlay/Sonos/Hue devices living on the IoT VLAN.
  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = [
      lan
      iot
    ];
    # Opened per interface above instead of globally (wan0).
    openFirewall = false;
  };

  systemd.network = {
    enable = true;

    config.networkConfig = {
      SpeedMeter = true;
    };

    # TODO: allow hotplug for all

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

    netdevs."20-iot" = {
      netdevConfig = {
        Kind = "vlan";
        Name = iot;
      };
      vlanConfig.Id = 20;
    };

    networks = {
      "10-wan" = {
        matchConfig.Name = wan;
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = "prefer-public";
          IPv4Forwarding = true;
          IPv6Forwarding = true;
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
        # Tagged VLANs carried on the same port.
        vlan = [ iot ];
        address = [
          "${config.${namespace}.myipv4}/24"
        ];
        addresses = [
          {
            # Stable ULA (from generated prefix fd83:c8db:133a::/48) for services, notably DNS:
            # unlike the delegated global prefix it never changes.
            Address = "${config.${namespace}.myipv6}/64";
            # Usable immediately so blocky can bind it at boot.
            DuplicateAddressDetection = "none";
          }
        ];
        networkConfig = {
          # v4 stuff
          DHCPServer = true; # v4
          IPv4Forwarding = true;
          IPv6Forwarding = true;

          # v6 stuff
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;

          IPv4ProxyARP = true;
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
        dhcpServerStaticLeases = staticLeasesIn "192.168.1.";

        # v6
        dhcpPrefixDelegationConfig = {
          SubnetId = 1;
        };
        ipv6SendRAConfig = {
          EmitDNS = true;
          DNS = config.${namespace}.myipv6;
        };
        linkConfig.RequiredForOnline = "routable";
      };

      "20-iot" = {
        matchConfig.Name = iot;
        address = [ "${iotAddress}/24" ];
        networkConfig = {
          DHCPServer = true; # v4
          IPv4Forwarding = true;
          IPv6Forwarding = true;

          IPv6AcceptRA = false;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
        };
        dhcpServerConfig = {
          PoolOffset = 50;
          PoolSize = 100;
          EmitDNS = true;
          EmitRouter = true;
          # blocky listens on the lan0 addresses, reachable from here via jonsnow's input chain.
          DNS = config.${namespace}.myipv4;
        };
        dhcpServerStaticLeases = staticLeasesIn "192.168.20.";
        dhcpPrefixDelegationConfig.SubnetId = 2;
        ipv6SendRAConfig = {
          EmitDNS = true;
          DNS = config.${namespace}.myipv6;
        };
        # Not needed for boot; may have no clients.
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

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
