{
  config,
  lib,
  modulesPath,
  ...
}:
{
  boot.initrd = {
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
  };
  boot.kernelModules = [ "kvm-intel" ];

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # Module for network:
  #         # 10G network card
  #         "atlantic"
}
