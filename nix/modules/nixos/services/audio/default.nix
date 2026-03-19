{ config, lib, ... }:
{
  # Enable sound.
  config = lib.mkIf config.nicdumz.device.isGraphical {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
