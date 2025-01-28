{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.prometheus;
in
{
  options.${namespace}.prometheus = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Prometheus.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      let
        sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
      in
      {
        deadmanssnitch_url = {
          inherit sopsFile;
          owner = "alertmanager";
          group = "nogroup";
        };
        telegram_token = {
          inherit sopsFile;
          owner = "alertmanager";
          group = "nogroup";
        };
        prometheus_password = {
          inherit sopsFile;
          owner = "prometheus";
          group = "nogroup";
        };
      };

    services.prometheus = {
      enable = true;
      retentionTime = "14d";
      listenAddress = "127.0.0.1";
      # port = 9090; # default

      alertmanager = {
        enable = true;
        listenAddress = "127.0.0.1";
        # port = 9093 # default
        configuration = {
          route = {
            receiver = "telegram";
            repeat_interval = "4h";
            group_by = [ "alertname" ];
            routes = [
              {
                receiver = "dead-man-snitch";
                matchers = [ ''service="deadman"'' ];
                repeat_interval = "10m";
              }
            ];
          };
          receivers = [
            # Default receiver sends a ping to a group chat.
            {
              name = "telegram";
              telegram_configs = [
                {
                  bot_token_file = config.sops.secrets.telegram_token.path;
                  chat_id = -797768186;
                  api_url = "https://api.telegram.org";
                  send_resolved = true;
                  parse_mode = "HTML";
                  message = ''
                    {{ define "alert_details" }}
                    - <b>Alert Name:</b> {{ .Labels.alertname }}
                      <b>Summary:</b> {{ .Annotations.summary }}
                      <b>Severity:</b> {{ .Labels.severity }}
                      <b>Description:</b>{{ .Annotations.description }}
                      <b>Status</b>: {{ .Status }}
                    {{ end }}

                    {{ if gt (len .Alerts.Firing) 0 }}🚨 {{if gt (len .Alerts.Firing) 1 }}Active Alerts{{else}}Active Alert{{end}} ({{ len .Alerts.Firing }})
                    {{ range .Alerts.Firing }}
                    {{ template "alert_details" . }}
                    {{ end }}{{ end }}

                    {{ if gt (len .Alerts.Resolved) 0 }}✅ {{if gt (len .Alerts.Resolved) 1 }}Resolved Alerts{{else}}Resolved Alert{{end}} ({{ len .Alerts.Resolved }})
                    {{ range .Alerts.Resolved }}
                    {{ template "alert_details" . }}
                    {{ end }}{{ end }}
                  '';
                }
              ];
            }
            # We ping every 10 mins a URL and if this URL / service doesn't hear
            # back it emails us after 1h.
            {
              name = "dead-man-snitch";
              webhook_configs = [
                { url_file = config.sops.secrets.deadmanssnitch_url.path; }
              ];
            }
          ];
        };
      };
      alertmanagers = [
        {
          scheme = "http";
          static_configs = [ { targets = [ "127.0.0.1:9093" ]; } ];
        }
      ];

      # TODO
      # services.prometheus.exporters.node.firewallFilter maybe
      # "--path.procfs=/host/proc"
      # "--path.rootfs=/rootfs"
      # "--path.sysfs=/host/sys"
      # "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|run)($|/)"
      exporters = {
        node = {
          listenAddress = "127.0.0.1";
          # port = 9100; # default
          enabledCollectors = [
            "filesystem"
            "processes"
            "systemd"
          ];
          enable = true;
        };
        blackbox = {
          listenAddress = "127.0.0.1";
          # port = 9115; # default
          enable = true;
          configFile = ./blackbox.yml;
        };
      };

      globalConfig = {
        scrape_interval = "15s";
        external_labels.instance = config.networking.hostName;
      };

      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.port}"
              ];
            }
          ];
        }
        {
          job_name = "alertmanager";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
              ];
            }
          ];
        }
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              ];
            }
          ];
        }
        {
          job_name = "blackbox";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.blackbox.port}"
              ];
            }
          ];
        }
        {
          job_name = "blocky";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.blocky.settings.ports.http}"
              ];
            }
          ];
        }
        {
          job_name = "traefik";
          scrape_interval = "30s";
          static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
        }
        {
          job_name = "blackbox-http";
          metrics_path = "/probe";
          params = {
            module = [ "http_2xx" ];
            target = [ "google.com" ];
          };
          static_configs = [
            {
              targets = [
                "https://amazon.com"
                "https://www.google.com"
                "https://www.init7.net"
              ];
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:${toString config.services.prometheus.exporters.blackbox.port}";
            }
          ];
        }
      ];

      ruleFiles = [ ./alert_rules.yml ];

      remoteWrite = [
        {
          url = "https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push";
          basic_auth = {
            username = "542370";
            password_file = config.sops.secrets.prometheus_password.path;
          };
          write_relabel_configs = [
            {
              source_labels = [ "__name__" ];
              action = "keep";
              # this monster comes from https://grafana.com/docs/grafana-cloud/billing-and-usage/control-prometheus-metrics-usage/usage-analysis-mimirtool/
              regex = "node_systemd_unit_state|go_gc_duration_seconds_sum|go_memstats_alloc_bytes|go_memstats_alloc_bytes_total|go_memstats_buck_hash_sys_bytes|go_memstats_gc_sys_bytes|go_memstats_heap_alloc_bytes|go_memstats_heap_idle_bytes|go_memstats_heap_inuse_bytes|go_memstats_heap_released_bytes|go_memstats_heap_sys_bytes|go_memstats_mcache_inuse_bytes|go_memstats_mcache_sys_bytes|go_memstats_mspan_inuse_bytes|go_memstats_mspan_sys_bytes|go_memstats_next_gc_bytes|go_memstats_other_sys_bytes|go_memstats_stack_inuse_bytes|go_memstats_stack_sys_bytes|go_memstats_sys_bytes|http_request_duration_microseconds_count|net_conntrack_dialer_conn_failed_total|node_arp_entries|node_boot_time_seconds|node_context_switches_total|node_cooling_device_cur_state|node_cooling_device_max_state|node_cpu_seconds_total|node_disk_discard_time_seconds_total|node_disk_discards_completed_total|node_disk_discards_merged_total|node_disk_io_now|node_disk_io_time_seconds_total|node_disk_io_time_weighted_seconds_total|node_disk_read_bytes_total|node_disk_read_time_seconds_total|node_disk_reads_completed_total|node_disk_reads_merged_total|node_disk_write_time_seconds_total|node_disk_writes_completed_total|node_disk_writes_merged_total|node_disk_written_bytes_total|node_entropy_available_bits|node_filefd_allocated|node_filefd_maximum|node_filesystem_avail_bytes|node_filesystem_device_error|node_filesystem_files|node_filesystem_files_free|node_filesystem_free_bytes|node_filesystem_readonly|node_filesystem_size_bytes|node_forks_total|node_hwmon_temp_celsius|node_hwmon_temp_crit_alarm_celsius|node_hwmon_temp_crit_celsius|node_hwmon_temp_crit_hyst_celsius|node_hwmon_temp_max_celsius|node_interrupts_total|node_intr_total|node_load1|node_load15|node_load5|node_memory_Active_anon_bytes|node_memory_Active_bytes|node_memory_Active_file_bytes|node_memory_AnonHugePages_bytes|node_memory_AnonPages_bytes|node_memory_Bounce_bytes|node_memory_Buffers_bytes|node_memory_Cached_bytes|node_memory_CommitLimit_bytes|node_memory_Committed_AS_bytes|node_memory_DirectMap1G_bytes|node_memory_DirectMap2M_bytes|node_memory_DirectMap4k_bytes|node_memory_Dirty_bytes|node_memory_HardwareCorrupted_bytes|node_memory_HugePages_Free|node_memory_HugePages_Rsvd|node_memory_HugePages_Surp|node_memory_HugePages_Total|node_memory_Hugepagesize_bytes|node_memory_Inactive_anon_bytes|node_memory_Inactive_bytes|node_memory_Inactive_file_bytes|node_memory_KernelStack_bytes|node_memory_Mapped_bytes|node_memory_MemFree_bytes|node_memory_MemTotal_bytes|node_memory_Mlocked_bytes|node_memory_NFS_Unstable_bytes|node_memory_PageTables_bytes|node_memory_Percpu_bytes|node_memory_SReclaimable_bytes|node_memory_SUnreclaim_bytes|node_memory_ShmemHugePages_bytes|node_memory_ShmemPmdMapped_bytes|node_memory_Shmem_bytes|node_memory_Slab_bytes|node_memory_SwapCached_bytes|node_memory_SwapFree_bytes|node_memory_SwapTotal_bytes|node_memory_Unevictable_bytes|node_memory_VmallocChunk_bytes|node_memory_VmallocTotal_bytes|node_memory_VmallocUsed_bytes|node_memory_WritebackTmp_bytes|node_memory_Writeback_bytes|node_netstat_Icmp_InErrors|node_netstat_Icmp_InMsgs|node_netstat_Icmp_OutMsgs|node_netstat_IpExt_InOctets|node_netstat_IpExt_OutOctets|node_netstat_Ip_Forwarding|node_netstat_TcpExt_ListenDrops|node_netstat_TcpExt_ListenOverflows|node_netstat_TcpExt_SyncookiesFailed|node_netstat_TcpExt_SyncookiesRecv|node_netstat_TcpExt_SyncookiesSent|node_netstat_TcpExt_TCPSynRetrans|node_netstat_Tcp_ActiveOpens|node_netstat_Tcp_CurrEstab|node_netstat_Tcp_InErrs|node_netstat_Tcp_InSegs|node_netstat_Tcp_MaxConn|node_netstat_Tcp_OutRsts|node_netstat_Tcp_OutSegs|node_netstat_Tcp_PassiveOpens|node_netstat_Tcp_RetransSegs|node_netstat_UdpLite_InErrors|node_netstat_Udp_InDatagrams|node_netstat_Udp_InErrors|node_netstat_Udp_NoPorts|node_netstat_Udp_OutDatagrams|node_netstat_Udp_RcvbufErrors|node_netstat_Udp_SndbufErrors|node_network_carrier|node_network_mtu_bytes|node_network_receive_bytes_total|node_network_receive_compressed_total|node_network_receive_drop_total|node_network_receive_errs_total|node_network_receive_fifo_total|node_network_receive_frame_total|node_network_receive_multicast_total|node_network_receive_packets_total|node_network_speed_bytes|node_network_transmit_bytes_total|node_network_transmit_carrier_total|node_network_transmit_colls_total|node_network_transmit_compressed_total|node_network_transmit_drop_total|node_network_transmit_errs_total|node_network_transmit_fifo_total|node_network_transmit_packets_total|node_network_transmit_queue_length|node_network_up|node_nf_conntrack_entries|node_nf_conntrack_entries_limit|node_power_supply_online|node_processes_max_processes|node_processes_max_threads|node_processes_pids|node_processes_state|node_processes_threads|node_procs_blocked|node_procs_running|node_schedstat_running_seconds_total|node_schedstat_timeslices_total|node_schedstat_waiting_seconds_total|node_scrape_collector_duration_seconds|node_scrape_collector_success|node_sockstat_FRAG_inuse|node_sockstat_FRAG_memory|node_sockstat_RAW_inuse|node_sockstat_TCP_alloc|node_sockstat_TCP_inuse|node_sockstat_TCP_mem|node_sockstat_TCP_mem_bytes|node_sockstat_TCP_orphan|node_sockstat_TCP_tw|node_sockstat_UDPLITE_inuse|node_sockstat_UDP_inuse|node_sockstat_UDP_mem|node_sockstat_UDP_mem_bytes|node_sockstat_sockets_used|node_softnet_dropped_total|node_softnet_processed_total|node_softnet_times_squeezed_total|node_systemd_socket_accepted_connections_total|node_systemd_units|node_textfile_scrape_error|node_time_seconds|node_timex_estimated_error_seconds|node_timex_frequency_adjustment_ratio|node_timex_loop_time_constant|node_timex_maxerror_seconds|node_timex_offset_seconds|node_timex_sync_status|node_timex_tai_offset_seconds|node_timex_tick_seconds|node_uname_info|node_vmstat_oom_kill|node_vmstat_pgfault|node_vmstat_pgmajfault|node_vmstat_pgpgin|node_vmstat_pgpgout|node_vmstat_pswpin|node_vmstat_pswpout|probe_dns_lookup_time_seconds|probe_duration_seconds|probe_http_duration_seconds|probe_http_ssl|probe_http_status_code|probe_http_version|probe_ssl_earliest_cert_expiry|probe_success|process_cpu_seconds_total|process_max_fds|process_open_fds|process_resident_memory_max_bytes|process_virtual_memory_bytes|process_virtual_memory_max_bytes|prometheus_config_last_reload_success_timestamp_seconds|prometheus_config_last_reload_successful|prometheus_engine_query_duration_seconds_sum|prometheus_evaluator_duration_seconds_count|prometheus_evaluator_duration_seconds_sum|prometheus_evaluator_iterations_missed_total|prometheus_evaluator_iterations_skipped_total|prometheus_evaluator_iterations_total|prometheus_notifications_sent_total|prometheus_rule_evaluation_failures_total|prometheus_sd_azure_refresh_failures_total|prometheus_sd_consul_rpc_failures_total|prometheus_sd_dns_lookup_failures_total|prometheus_sd_ec2_refresh_failures_total|prometheus_sd_gce_refresh_failures_total|prometheus_sd_marathon_refresh_failures_total|prometheus_sd_openstack_refresh_failures_total|prometheus_sd_triton_refresh_failures_total|prometheus_target_interval_length_seconds|prometheus_target_interval_length_seconds_count|prometheus_target_scrape_pool_sync_total|prometheus_target_scrapes_exceeded_sample_limit_total|prometheus_target_scrapes_sample_duplicate_timestamp_total|prometheus_target_scrapes_sample_out_of_bounds_total|prometheus_target_scrapes_sample_out_of_order_total|prometheus_target_sync_length_seconds_sum|prometheus_treecache_zookeeper_failures_total|prometheus_tsdb_compactions_failed_total|prometheus_tsdb_head_chunks|prometheus_tsdb_head_samples_appended_total|prometheus_tsdb_head_series|prometheus_tsdb_head_series_created_total|prometheus_tsdb_head_series_not_found|prometheus_tsdb_head_series_removed_total|prometheus_tsdb_reloads_failures_total|scrape_duration_seconds|traefik_entrypoint_requests_total|traefik_service_request_duration_seconds_sum|traefik_service_requests_total|up|";
            }
          ];
        }
      ];
    };

    services.grafana.provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.prometheus.port}";
      }
    ];
  };
}
