{
  channels,
  ...
}:

_final: _prev: {
  # VSCodium from 24.11 is too old for latest vscode extensions.
  inherit (channels.nixpkgs-unstable) vscodium;
}
