{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace};
in
{
  options.${namespace} = {
    work = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable work apps.";
      };
    };
  };

  config = lib.mkIf cfg.work.enable {
    services.tailscale.enable = true;
    environment.systemPackages =
      with pkgs;
      [
        bazelisk
        buildifier
        uv
        # aspect-cli
        tailscale
      ]
      ++ (lib.optionals cfg.device.isGraphical [ slack ]);

    # https://nix.dev/permalink/stub-ld sadness
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib # libstdc++ — Bazel sometimes shells out to clang/g++ wrappers
        zlib # common Bazel transitive dep
      ];
    };
  };

}
