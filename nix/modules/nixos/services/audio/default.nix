{ config, lib, ... }:
{
  # Enable sound.
  config = lib.mkIf config.nicdumz.graphical {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
