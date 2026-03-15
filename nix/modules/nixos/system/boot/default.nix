{
  config,
  inputs,
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
    # Manual styling below
    catppuccin.limine.enable = false;

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
        # I generally use limine so the generations / titles dont take most of the screen width.
        limine =
          let
            res = config.${namespace}.boot.resolution;
          in
          {
            enable = true;
            # TODO 26.05 enable and remove below
            # resolution = res;
            style = {
              interface.brandingColor = 4; # blue from below
              interface.resolution = res;
              wallpapers = [
                (inputs.self.outPath + "/assets/wallpapers/horizon-2.jpg")
              ];
              wallpaperStyle = "centered";
            };
            maxGenerations = 7;
            extraConfig =
              let
                # used to expand the comment + above title: use Flamingo
                cyan = "f2cdcd";
                # For instructions, use Marroon
                green = "ea999c";
              in
              ''
                resolution: ${res}
                remember_last_entry: yes

                # below is the catppuccin mocha theme, with:
                #  - a transparent background
                #  - custom color assignments (from Mocha)
                term_palette: 1e1e2e;f38ba8;${green};f9e2af;89b4fa;f5c2e7;${cyan};cdd6f4
                term_palette_bright: 585b70;f38ba8;${green};f9e2af;89b4fa;f5c2e7;${cyan};cdd6f4
                # transparency + RGB
                # Higher transparency value=more transparent (bg image is more visible)
                term_background: 801e1e2e
                term_foreground: cdd6f4
                term_background_bright: 585b70
                term_foreground_bright: cdd6f4
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
