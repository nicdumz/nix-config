{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Before overwriting a non-managed file, move it to .backup
    backupFileExtension = "backup";
  };
}
