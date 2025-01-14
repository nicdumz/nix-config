{
  namespace,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./configuration.nix
    ./windows-dual.nix
  ];

  disko.devices = lib.${namespace}.mkEncryptedDiskLayout "32";

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
  };

  # TODO: package in a module
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;
    open = true; # required for RTX
  };

  # TODO: package in a module
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [ "qwen2.5-coder:1.5b" ];
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      # Cuda (for ollama) is unfree.
      "cuda_cccl"
      "cuda_cudart"
      "cuda_nvcc"
      "libcublas"
      # nvidia drivers
      "nvidia-x11"
      "nvidia-settings"
    ];
}
