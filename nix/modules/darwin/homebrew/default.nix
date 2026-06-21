{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.homebrew;
in
{
  options.${namespace}.homebrew = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Manage Homebrew declaratively via nix-darwin.";
    };
  };

  # Homebrew is reserved for GUI apps whose official installer wires up macOS
  # system extensions / privileged helpers that the nixpkgs build does not:
  #   - orbstack:  privileged helper + VM + Docker networking (provides `docker`)
  #   - tailscale: GUI + macOS Network Extension + corp SSO/MDM
  # Everything else comes from nixpkgs. Work-specific casks are appended by the
  # consuming (private) system config; `casks` lists merge across modules.
  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      casks = [
        "orbstack"
        "tailscale"
      ];
      onActivation = {
        # Uninstall any formula/cask not declared across the merged config.
        cleanup = "uninstall";
        # Refresh the catalog and upgrade managed packages on each rebuild.
        autoUpdate = true;
        upgrade = true;
      };
    };
  };
}
