{
  channels,
  ...
}:

_final: _prev: {
  # Always pick up the latest VSCodium. Helps with extension compatibility.
  inherit (channels.nixpkgs-unstable) vscodium;
  inherit (channels.nixpkgs-unstable) home-assistant;
  # The version in stable is insecure
  inherit (channels.nixpkgs-unstable) fosrl-pangolin;
  inherit (channels.nixpkgs-unstable) zensical;
}
