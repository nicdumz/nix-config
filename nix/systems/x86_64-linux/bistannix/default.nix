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
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [ "qwen2.5-coder:1.5b" ];
  };

  # Cuda (for ollama) is unfree.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "cuda_cccl"
      "cuda_cudart"
      "cuda_nvcc"
      "libcublas"
    ];
}
