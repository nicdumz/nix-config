{ inputs, lib, ... }:
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
        oneLink = directory: programName: "ln -s ${directory}/${programName} $out/bin/${programName}";
        mkLink =
          {
            packageName,
            programNames ? [ packageName ],
            directory ? "/usr/bin",
            ... # We purposedly ignore other args, which would come from overrides
          }:
          prev.runCommand "${packageName}-system-link"
            {
              # first program is considered important
              meta.mainProgram = builtins.head programNames;
            }
            (
              lib.strings.concatLines [
                "mkdir -p $out/bin"
                (lib.strings.concatMapStringsSep "\n" (oneLink directory) programNames)
              ]
            );
      in
      builtins.listToAttrs (
        map (
          m:
          let
            args = if builtins.isString m then { packageName = m; } else m;
          in
          lib.throwIf (args.packageName == "git")
            "Putting 'git' in systemLinks breaks nixpkgs functional tests which uses git.overrides"
            {
              name = args.packageName;
              value = lib.makeOverridable mkLink args;
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
      # List of links to create against the standalone system.
      # Created as overlays of nix packages.
      # Each element can either be:
      #  - a {packageName: string, programNames ? [ packageName ], directory ? "/usr/bin"} attribute
      #  - a string, which is interpreted as a {packageName} attribute
      # The following example is a replacement of nixpkgs.hyprland:
      #  {
      #    packageName = "hyprland";
      #    programNames = ["hyprland" "hyprctl" "Hyprland"];
      #  }
      systemLinks ? [ ],
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
