{
  lib,
  inputs,
  pkgs,
  system,
  ...
}:
{
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = system;

  # https://nixos.wiki/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = "github:nicdumz/nix-config";
    flags = [
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  ## Below is to align shell/system to flake's nixpkgs
  ## ref: https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry

  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  nix = {
    # this helps nixd find the right completions etc.
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    registry.nixpkgs.flake = inputs.nixpkgs;
    channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

    # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one
    # used by this flake.
    # https://github.com/NixOS/nix/issues/9574
    settings.nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";

    # Perform garbage collection weekly to maintain low disk usage
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };

    ###

    settings = {

      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Substitutions
      substituters = [
        "https://cache.garnix.io"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];

      # Fallback quickly if substituters are not available.
      connect-timeout = 25;

      trusted-users = [
        "root"
        "@wheel"
      ];

      # The default at 10 is rarely enough.
      log-lines = lib.mkDefault 25;

      # Optimize storage
      # You can also manually optimize the store via:
      #    nix-store --optimise
      # Refer to the following link for more details:
      # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
      auto-optimise-store = true;

      # Very confused but apparently https://github.com/nix-community/home-manager/pull/3876 wants this.
      use-xdg-base-directories = true;
    };
  };

  environment.systemPackages = with pkgs; [
    nixd
    nixfmt-rfc-style
  ];

}
