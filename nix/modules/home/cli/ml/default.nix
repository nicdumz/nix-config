{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  isGraphical = config.${namespace}.device.isGraphical;
  herdrPlugins = inputs.herdr-plugins.legacyPackages.${system}.herdrPlugins;
in
{
  imports = [
    inputs.oh-my-pi.homeManagerModules.default
    # Not on our pinned home-manager's release branch yet; sourced by path
    # from home-manager-unstable (tracks master) instead of vendoring it.
    "${inputs.home-manager-unstable}/modules/programs/herdr.nix"
    inputs.herdr-plugins.homeModules.herdr
  ];

  # AI coding tooling (omp, herdr) -- only useful where there's an
  # interactive terminal/IDE session to drive, not on headless servers.
  programs.omp = {
    enable = isGraphical;
    settings = {
      # Without this, omp's `eval` tool (Python cells) looks for `python3`
      # on PATH and fails outside a shell that happens to have one. Point
      # it at the Nix store path directly instead of also adding python3
      # to home.packages -- pinned, and doesn't depend on PATH
      # contents/order.
      python.interpreter = "${pkgs.python3}/bin/python3";
      composer.shape = "band";
      theme.dark = "dark-catppuccin";
    };
  };
  programs.herdr = {
    enable = isGraphical;
    # Official prebuilt binary (herdr.cachix.org), not nixpkgs' from-source build.
    package = inputs.herdr.packages.${system}.default;
    plugins = lib.mkIf isGraphical [ herdrPlugins.herdr-reviewr ];
  };

  home.packages = lib.mkIf isGraphical [ pkgs.bazelisk ];

  # `omp completions fish` can't be pre-generated in a derivation: the
  # compiled binary self-extracts (or downloads, if missing) native bindings
  # into $HOME on first run, which the build sandbox's unwritable fake $HOME
  # and network isolation both block (verified directly: build fails trying
  # to write/fetch /homeless-shelter/.omp/natives/...). Generate the
  # completions file once per activation instead of on every shell startup.
  home.activation.ompFishCompletions = lib.mkIf isGraphical (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/fish/completions"}
      run ${lib.getExe config.programs.omp.package} completions fish \
        > ${lib.escapeShellArg "${config.xdg.configHome}/fish/completions/omp.fish"} \
        || true
    ''
  );
}
