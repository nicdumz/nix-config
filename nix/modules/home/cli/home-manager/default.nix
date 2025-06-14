{
  inputs,
  config,
  ...
}:
{
  programs.home-manager.enable = true;

  # For nixd
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  home = {
    stateVersion = "25.05";
    preferXdgDirectories = true;
    # https://github.com/NixOS/nixpkgs/issues/12757
    activation.linkDesktopFiles = config.lib.dag.entryAfter [ "installPackages" ] ''
      if [ -d "${config.home.profileDirectory}/share/applications" ]; then
        rm -rf ${config.home.homeDirectory}/.local/share/applications
        mkdir -p ${config.home.homeDirectory}/.local/share/applications
        for file in ${config.home.profileDirectory}/share/applications/*; do
          ln -sf "$file" ${config.home.homeDirectory}/.local/share/applications/
        done
      fi
    '';
  };
}
