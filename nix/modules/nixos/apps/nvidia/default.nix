{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.nvidia;
in
{
  options.${namespace}.nvidia = with lib.types; {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Enable NVIDIA GPU support. Disabled for now because unstable.";
    };
  };

  config = lib.mkIf cfg.enable {
    # 25.05: IMO it's strange to have this configured here when the OS runs wayland.
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      # NOTE: if off, then screen-tearing appears when waking up from sleep. If it's on, random
      # crashes happen when waking up. Nothing actually works :))
      # powerManagement.enable = true; # Try that to avoid tearing?
      open = true; # required for RTX

      # The following are now defaults AFAICT
      # # Modesetting is required, for wayland etc.
      # # modesetting.enable = true;
    };

    # # TODO: package in a separate module if I keep that.
    # services.ollama = {
    #   enable = true;
    #   acceleration = "cuda";
    #   loadModels = [ "qwen2.5-coder:1.5b" ];
    # };

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        #   # Cuda (for ollama) is unfree.
        #   "cuda_cccl"
        #   "cuda_cudart"
        #   "cuda_nvcc"
        #   "libcublas"
        # nvidia drivers
        "nvidia-x11"
        "nvidia-settings"
      ];
  };
}
