{
  channels,
  ...
}:

_final: _prev: {
  # VSCodium from 24.11 is too old for latest vscode extensions.
  # TODO: can we remove this override as of 25.05?
  inherit (channels.nixpkgs-unstable) vscodium;
}
