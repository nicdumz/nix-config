let
  fromYAML =
    pkgs: yaml:
    builtins.fromJSON (
      builtins.readFile (
        pkgs.runCommand "from-yaml"
          {
            inherit yaml;
            allowSubstitutes = false;
            preferLocalBuild = true;
          }
          ''
            ${pkgs.remarshal}/bin/remarshal  \
              -if yaml \
              -i <(echo "$yaml") \
              -of json \
              -o $out
          ''
      )
    );

  readYAML = pkgs: path: fromYAML pkgs (builtins.readFile path);

in
{
  inherit fromYAML readYAML;
}
