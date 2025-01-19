# Everything else goes here.

{
  lib,
  ...
}:

{
  imports = [
    ./options.nix
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    cpu.amd.updateMicrocode = true;
  };

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_GB.UTF-8";
}
