# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:

{
  imports = [
    ./graphical.nix
    ./nix.nix
    ./options.nix
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
    inputs.impermanence.nixosModules.impermanence
  ];

  system.stateVersion = "24.11";

  security.sudo.extraConfig = "Defaults insults,timestamp_timeout=30";

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  boot = {
    initrd = {
      kernelModules = [
        "nvme"
        "usbhid" # fido2 over usb
        # yubico
        "nls_cp437"
        "nls_iso8859-1"
      ];
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      systemd.enable = true;
    };

    loader = {
      efi.canTouchEfiVariables = true;
      # TODO: I would technically prefer refind (for prettiness), but no
      # declarative way to expose generations for now, so use systemd-boot.
      grub.enable = false;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
        # highlight last booted
        extraInstallCommands = ''
          ${pkgs.gnused}/bin/sed -i 's/default nixos-generation-[0-9][0-9].conf/default @saved/g' /boot/loader/loader.conf
        '';
      };
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    cpu.amd.updateMicrocode = true;
  };

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_GB.UTF-8";

  services.openssh.enable = true;

  nixpkgs.hostPlatform = system;
  # https://nixos.wiki/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # I spent too much time on this but those are settings for the system integration of
  # home-manager, thus belong in nixconfiguration.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Before overwriting a non-managed file, move it to .backup
    backupFileExtension = "backup";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    colordiff
    efibootmgr
    git
    killall
    libfido2 # provides fido2-token utility
    nixd
    nixfmt-rfc-style
    unzip
    wget
  ];
}
