{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.ollama;
in
{
  options.${namespace}.ollama = with lib.types; {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Enable ollama.";
    };
    bar = lib.mkOption {
      description = "Enable ollama bar.";
      type = bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    # Otherwise we fill up / (and redownload models).
    ${namespace}.persistence.directories = [ config.services.ollama.home ];
    services.ollama = {
      enable = true;
      acceleration =
        if builtins.elem "amdgpu" config.services.xserver.videoDrivers then "rocm" else "cuda";
      # remove models added locally but not configured.
      syncModels = true;
      loadModels = [
        "nate/instinct"
        # "qwen2.5-coder:14b-base-q8_0"
        # "qwen2.5-coder:7b-base-q8_0"
      ];
      environmentVariables = {
        "OLLAMA_FLASH_ATTENTION" = "true";
        "OLLAMA_KV_CACHE_TYPE" = "q8_0";
      };
    };
  };
}
