{
  fromYAML =
    pkgs: f:
    let
      jsonFile =
        pkgs.runCommand "in.json"
          {
            nativeBuildInputs = [ pkgs.jc ];
          }
          ''
            jc --yaml < "${f}" > "$out"
          '';
    in
    builtins.elemAt (builtins.fromJSON (builtins.readFile jsonFile)) 0;
}
