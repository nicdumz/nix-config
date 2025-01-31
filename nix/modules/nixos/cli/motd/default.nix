# Inspired by truxnell.
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  motd = pkgs.writeShellScriptBin "motd" ''
    #! /usr/bin/env bash
    source /etc/os-release
    service_status=$(systemctl list-units ${services} | grep ".service" | sed -e 's/^[● ]\+//' -e 's/\(docker\|podman\)-//g' -e 's/.service//' | sort)
    RED="\e[31m"
    GREEN="\e[32m"
    BOLD="\e[1m"
    ENDCOLOR="\e[0m"
    LOAD1=`cat /proc/loadavg | awk {'print $1'}`
    LOAD5=`cat /proc/loadavg | awk {'print $2'}`
    LOAD15=`cat /proc/loadavg | awk {'print $3'}`

    MEMORY=`free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100 / $2 }'`

    uptime=`cat /proc/uptime | cut -f1 -d.`
    upDays=$((uptime/60/60/24))
    upHours=$((uptime/60/60%24))
    upMins=$((uptime/60%60))

    figlet "$(hostname)" | lolcat -f
    printf "\n"
    ${lib.strings.concatStrings (
      lib.lists.forEach cfg.networkInterfaces (
        x:
        "printf \"$BOLD  * %-30s$ENDCOLOR %s\\n\" \"IPv4 ${x}\" \"$(ip -4 addr show ${x} | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}')\"\n"
      )
    )}
    printf "$BOLD  * %-30s$ENDCOLOR %s\n" "Release" "$PRETTY_NAME"
    printf "$BOLD  * %-30s$ENDCOLOR %s\n" "Kernel" "$(uname -rs)"
    [ -f /var/run/reboot-required ] && printf "$RED  * %-30s$ENDCOLOR %s\n" "A reboot is required"
    printf "\n"
    printf "$BOLD  * %-30s$ENDCOLOR %s\n" "CPU usage" "$LOAD1, $LOAD5, $LOAD15 (1, 5, 15 min)"
    printf "$BOLD  * %-30s$ENDCOLOR %s\n" "Memory" "$MEMORY"
    printf "$BOLD  * Disk usage$ENDCOLOR %s\n"
    ${lib.strings.concatStrings (
      lib.lists.forEach cfg.fileSystems (
        x:
        "printf \"$BOLD    \\055 %-28s$ENDCOLOR %s\\n\" \"${x}\" \"$(df -h ${x} | tail -n1 | awk '{print $5;}')\"\n"
      )
    )}
    printf "$BOLD  * %-30s$ENDCOLOR %s\n" "System uptime" "$upDays days $upHours hours $upMins minutes"
    printf "\n"
    printf "$BOLD Service status$ENDCOLOR\n"

    while IFS= read -r line; do
      if [[ $line =~ ".scope" ]]; then
        continue
      fi
      service_name=$(echo $line | awk '{print $1;}')
      if echo "$line" | grep -q 'failed'; then
        printf " $RED• $ENDCOLOR%-50s $RED[failed]$ENDCOLOR\n" "$service_name"
      elif echo "$line" | grep -q 'running'; then
        printf " $GREEN• $ENDCOLOR%-50s $GREEN[active]$ENDCOLOR\n" "$service_name"
      else
        printf " • $ENDCOLOR%-50s [unknown]\n" "$service_name"
      fi
    done <<< "$service_status"
  '';
  cfg = config.${namespace}.motd;
  services = lib.strings.concatMapStringsSep " " (s: s + ".service") cfg.systemdServices;
in
{
  options.${namespace}.motd = {
    enable = lib.mkEnableOption "MOTD";
    networkInterfaces = lib.mkOption {
      description = "Network interfaces to display";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    fileSystems = lib.mkOption {
      description = "Filesystems to report on.";
      type = lib.types.listOf lib.types.str;
      default = [
        "/media/bigslowdata"
        "/nix"
      ];
    };
    systemdServices = lib.mkOption {
      description = "Systemd service units to watch for.";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      motd
      pkgs.lolcat
      pkgs.figlet
    ];
    programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
      motd
    '';
  };
}
