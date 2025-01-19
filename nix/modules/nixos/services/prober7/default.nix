{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.prober7;
in
{
  options.${namespace}.prober7 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable prober7 probes.";
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets.prober7_probe_id = { };
    services.cron = {
      enable = true;
      systemCronJobs =
        let
          tokenPath = config.sops.secrets.prober7_probe_id.path;
          probeUrl = sink: "\"http://prober7-${sink}.zekjur.net:42070/lightprobe/$(cat ${tokenPath})\"";
        in
        [
          "* * * * * curl -s -o /dev/null ${probeUrl "sink"} ${probeUrl "sink6"}"
        ];
    };
  };
}
