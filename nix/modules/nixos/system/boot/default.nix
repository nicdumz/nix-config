{ pkgs, ... }:
{
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
      # NOTE: I would technically prefer refind (for prettiness), but there is no
      # declarative way to expose generations for now, so use systemd-boot.
      grub.enable = false;
      systemd-boot = {
        enable = true;
        configurationLimit = 7;
        editor = false;
        # highlight last booted
        extraInstallCommands = ''
          ${pkgs.gnused}/bin/sed -i 's/default nixos-generation-[0-9][0-9].conf/default @saved/g' /boot/loader/loader.conf
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
  ];
}
