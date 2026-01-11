{
  channels,
  ...
}:

_final: _prev: {
  # Always pick up the latest VSCodium. Helps with extension compatibility.
  inherit (channels.nixpkgs-unstable) vscodium;
  # Downgrade after https://github.com/NixOS/nixpkgs/issues/478145
  inherit (channels.nixpkgs-unstable) jackett;
}
