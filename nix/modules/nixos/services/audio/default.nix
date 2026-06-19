{ config, lib, ... }:
{
  # Enable sound.
  config = lib.mkIf config.nicdumz.device.isGraphical {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    # Prevent USB hub and webcam from autosuspending mid-call (causes camera drops in Google Meet).
    # The Realtek hub (0bda:0420) power-cycles all downstream devices when it suspends,
    # triggering uvcvideo URB errors and /dev/video0 disappearing briefly.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="0420", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="0893", ATTR{power/control}="on"
    '';
  };
}
