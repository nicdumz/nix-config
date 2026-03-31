{ inputs, ... }:
let
  # Setup symlinks to system-wide programs (instead of using binaries coming
  # from nix).
  # Tradeoff:
  #  + I use whatever Corp bundles, which complies ~exactly to Corp security
  #  policies.
  #  - I don't get freshest updates and maybe once in a while it'll surface
  #  some binary vs config incompatibilities. So be it.
  mkSystemLinkOverlay =
    mappings:
    (
      _final: prev:
      let
        mkLink =
          {
            packageName,
            programName ? packageName,
            directory ? "/usr/bin",
          }:
          prev.runCommand "${packageName}-system-link"
            {
              meta.mainProgram = programName;
            }
            ''
              mkdir -p $out/bin
              ln -s ${directory}/${programName} $out/bin/${programName}
            '';
      in
      builtins.listToAttrs (
        map (
          m:
          let
            args = if builtins.isString m then { packageName = m; } else m;
          in
          {
            name = args.packageName;
            value = mkLink args;
          }
        ) mappings
      )
    );
in
{
  mkCorpHome =
    {
      system ? "x86_64-linux",
      nixpkgs,
      overlays ? [ ],
      systemLinks,
      deviceType,
      localModules ? [ ],
      nicdumz,
    }:
    let
      basePkgs = nixpkgs.legacyPackages.${system};
      pkgs = basePkgs.appendOverlays (overlays ++ [ (mkSystemLinkOverlay systemLinks) ]);
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules =
        (builtins.attrValues nicdumz.homeModules)
        ++ localModules
        ++ [
          {
            nix.package = pkgs.nix;
            nicdumz = nicdumz.homeConfigurations.ndumazet.config.nicdumz // {
              device.type = deviceType;
            };
          }
        ];
    };
}
