_: {
  # TODO: Modularize so in theory this + nvidia enabling works.
  #  nixpkgs.config.allowUnfreePredicate =
  #    pkg:
  #    builtins.elem (lib.getName pkg) (
  #      lib.optionals config.snowfallorg.users.giulia.create [ "google-chrome" ]
  #    );
}
