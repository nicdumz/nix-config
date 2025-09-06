{ inputs, ... }:
{
  mkColmenaHive =
    nixpkgs: deployments:
    let
      confs = inputs.self.nixosConfigurations;
      colmenaConf = {
        meta = {
          inherit nixpkgs;
          nodeNixpkgs = builtins.mapAttrs (_name: value: value.pkgs) confs;
          nodeSpecialArgs = builtins.mapAttrs (_name: value: value._module.specialArgs) confs;
        };
      }
      // builtins.mapAttrs (name: value: {
        imports = value._module.args.modules;
        deployment = deployments.${name} or { };
      }) confs;
    in
    inputs.colmena.lib.makeHive colmenaConf;
}
