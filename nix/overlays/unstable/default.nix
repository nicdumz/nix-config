{
  channels,
  ...
}:

_final: _prev: {
  # Always pick up the latest VSCodium. Helps with extension compatibility.
  inherit (channels.nixpkgs-unstable) vscodium;
  # TODO: investigate if this is still needed.
  inherit (channels.nixpkgs-unstable) home-assistant;
  # The version in stable is insecure
  inherit (channels.nixpkgs-unstable) fosrl-pangolin;
  # 26.05: only exists as of 26.05, can be moved to stable afterwards.
  inherit (channels.nixpkgs-unstable) zensical;
  # Things are still moving a lot and unstable is a lot more useable.
  inherit (channels.nixpkgs-unstable) jujutsu;
}
