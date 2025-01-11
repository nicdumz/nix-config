# This module only exists so I can understand (via `nix repl`) what inputs are passed to modules.
args: {
  options.${args.namespace}.debug = args.lib.mkOption {
    description = "set anything you'd like to help debug";
    type =
      with args.lib.types;
      attrsOf (submodule {
        options = {
          description = args.lib.mkOption {
            type = str;
          };
          value = args.lib.mkOption {
            type = anything;
          };
        };
      });
  };
  config.${args.namespace}.debug = {
    args = {
      description = "args";
      value = args;
    };
    inputs = {
      description = "inputs";
      value = args.inputs;
    };
    self = {
      description = "inputs.self";
      value = args.inputs.self;
    };
    outPath = {
      description = "inputs.self.outPath";
      value = args.inputs.self.outPath;
    };
    getFile = {
      description = "get-file \"\"";
      value = args.lib.snowfall.fs.get-file "";
    };
    pathEq = {
      description = "get-file \"\" == inputs.self.outPath";
      value = (args.lib.snowfall.fs.get-file "") == args.inputs.self.outPath;
    };
    snowFallSrc = {
      description = "self.snowfall.config.src";
      value = args.inputs.self.snowfall.config.src;
    };
    # Why? Because left side is a path and right side is a string
    pathEq2 = {
      description = "self.snowfall.config.src == inputs.self.outPath";
      value = args.inputs.self.snowfall.config.src == args.inputs.self.outPath;
    };
  };
}
