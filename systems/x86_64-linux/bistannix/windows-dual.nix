# This file is https://wiki.nixos.org/wiki/Dual_Booting_NixOS_and_Windows#systemd-boot_2
_: {
  boot.loader.systemd-boot = {
    windows = {
      "11-home" =
        let
          # To determine the name of the windows boot drive, boot into edk2 first, then run
          # `map -c` to get drive aliases, and try out running `FS1:`, then `ls EFI` to check
          # which alias corresponds to which EFI partition.
          boot-drive = "HD1b";
        in
        {
          title = "Windows 11";
          efiDeviceHandle = boot-drive;
          sortKey = "y_windows";
        };
    };

    edk2-uefi-shell.enable = true;
    edk2-uefi-shell.sortKey = "z_edk2";
  };
}
