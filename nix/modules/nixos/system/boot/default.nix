{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.boot = {
    resolution = lib.mkOption {
      type = lib.types.str;
      default = "1920x1200";
    };
  };

  config = {
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
        timeout = 10;
        efi.canTouchEfiVariables = true;
        limine =
          let
            res = config.${namespace}.boot.resolution;
          in
          {
            enable = true;
            # TODO 26.05 enable and remove below
            # resolution = res;
            style.interface.resolution = res;
            maxGenerations = 7;
            extraConfig = ''
              resolution: ${res}
              remember_last_entry: yes
            '';
          };
      };
    };

    environment.systemPackages = with pkgs; [
      efibootmgr
      sbctl
    ];
    ${namespace}.persistence.directories = [ "/var/lib/sbctl" ];
  };
}
