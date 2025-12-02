{
  channels,
  ...
}:

_final: _prev: {
  # Always pick up the latest VSCodium. Helps with extension compatibility.
  inherit (channels.nixpkgs-unstable) vscodium;
}
