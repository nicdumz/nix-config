{ lib }:
let
  cfg = {
    presence = [
      {
        alert = "NodeExporterDown";
        expr = ''up{job="node"} < 1'';
        for = "5m";
      }
      {
        alert = "TraefikDown";
        expr = ''up{job="traefik"} < 1'';
        for = "5m";
      }
      {
        alert = "PrometheusAlertmanagerJobMissing";
        expr = ''absent(up{job="alertmanager"})'';
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Prometheus AlertManager job missing (instance {{ $labels.instance }})";
          description = "A Prometheus AlertManager job has disappeared
  VALUE = {{ $value }}
  LABELS = {{ $labels }}";
        };
      }
    ];
    host = [
      {
        # Please add ignored mountpoints in node_exporter parameters like
        # "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run)($|/)".
        # Same rule using "node_filesystem_free_bytes" will fire when disk fills for non-root users.
        alert = "HostOutOfDiskSpace";
        expr = "(node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 30 and ON (instance, device, mountpoint) node_filesystem_readonly == 0";
        for = "2m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Host out of disk space (instance {{ $labels.instance }})";
          description = "Disk is almost full (< 30% left)
  VALUE = {{ $value }}
  LABELS = {{ $labels }}";
        };
      }
      {
        alert = "HostPhysicalComponentTooHot";
        expr = "node_hwmon_temp_celsius > 75";
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Host physical component too hot (instance {{ $labels.instance }})";
          description = "Physical hardware component too hot
  VALUE = {{ $value }}
  LABELS = {{ $labels }}";
        };
      }
    ];
    probing = [
      {
        alert = "BlackboxProbeFailed";
        expr = "probe_success == 0";
        for = "5m";
        labels = {
          severity = "critical";
        };
        annotations = {
          summary = "Blackbox probe failed (instance {{ $labels.instance }})";
          description = "Probe failed
  VALUE = {{ $value }}
  LABELS = {{ $labels }}";
        };
      }
      {
        alert = "PrometheusAlertmanagerE2eDeadManSwitch";
        expr = "vector(1)";
        for = "0m";
        labels = {
          severity = "end2endtest";
          service = "deadman";
        };
        annotations = {
          summary = "Prometheus AlertManager E2E dead man switch (instance {{ $labels.instance }})";
          description = "Prometheus DeadManSwitch is an always-firing alert. It's used as an end-to-end test of Prometheus through the Alertmanager.
  LABELS = {{ $labels }}";
        };
      }
    ];
    misc = [
      {
        alert = "PrometheusTemplateTextExpansionFailures";
        expr = "increase(prometheus_template_text_expansion_failures_total[3m]) > 0";
        for = "0m";
        labels = {
          severity = "critical";
        };
        annotations = {
          summary = "Prometheus template text expansion failures (instance {{ $labels.instance }})";
          description = "Prometheus encountered {{ $value }} template text expansion failures
  VALUE = {{ $value }}
  LABELS = {{ $labels }}";
        };
      }
    ];
  };
in
{
  groups = lib.mapAttrsToList (n: v: {
    name = lib.strings.toSentenceCase n;
    rules = v;
  }) cfg;
}
