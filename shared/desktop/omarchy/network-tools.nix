# Top-bar network popup follow-up: ping/throughput/IP/gateway status and a
# manual speed test. Both scripts are ported near-verbatim from upstream
# Omarchy's own bin/omarchy-network-status and bin/omarchy-network-speedtest
# (github.com/omacom/omarchy, MIT licensed, quattro branch) at the user's
# explicit request to reuse upstream's real implementation rather than
# invent one -- self-contained, depend only on standard tools already used
# elsewhere in this repo (ip, jq, awk, nmcli, curl) plus `iw` and `dd`
# (added here). The only change from upstream is dropping the
# `omarchy-cmd-present <tool>` existence checks (an Omarchy-specific helper
# that doesn't exist in this repo) -- they only gated an early return when a
# tool was missing, which `runtimeInputs` already guarantees is never the
# case here.
{ pkgs, ... }:

let
  networkStatus = pkgs.writeShellApplication {
    name = "omarchy-network-status";
    runtimeInputs = [
      pkgs.iproute2
      pkgs.iw
      pkgs.networkmanager
      pkgs.jq
      pkgs.gawk
      pkgs.iputils
    ];
    text = ''
      verbose=false
      internet_probe=1.1.1.1

      case "''${1:-}" in
        "")
          ;;
        --verbose)
          verbose=true
          ;;
        *)
          echo "Usage: omarchy-network-status [--verbose]" >&2
          exit 2
          ;;
      esac

      print_status() {
        local device nm state ssid signal freq

        device=$(ip route get "$internet_probe" 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

        if [[ -z $device ]]; then
          printf 'disconnected\t\t\t\n'
          return
        fi

        if [[ ! -d /sys/class/net/$device/wireless ]]; then
          printf 'ethernet\t%s\t\t\n' "$device"
          return
        fi

        nm=$(nmcli -t -f GENERAL.STATE,GENERAL.CONNECTION dev show "$device" 2>/dev/null)
        state=$(awk -F: '$1 == "GENERAL.STATE" { print $2; exit }' <<<"$nm")
        ssid=$(awk -F: '$1 == "GENERAL.CONNECTION" { print $2; exit }' <<<"$nm")
        signal=$(nmcli -t -f IN-USE,SIGNAL dev wifi list ifname "$device" --rescan no 2>/dev/null | awk -F: '$1 == "*" { print $2; exit }')
        freq=$(iw dev "$device" link 2>/dev/null | awk '/freq:/ { print $2; exit }')

        if [[ $state != 100* ]]; then
          printf 'disconnected\t\t\t\n'
          return
        fi

        printf 'wifi\t%s\t%s\t%s\n' "''${ssid:-$device}" "$signal" "$freq"
      }

      ping_latency_ms() {
        local host=$1

        LC_ALL=C ping -n -c 1 -W 1 "$host" 2>/dev/null | awk -F'time[=<]' '/time[=<]/ { split($2, parts, " "); print parts[1]; exit }'
      }

      print_ping_samples() {
        local gateway=$1
        local tmpdir router_file internet_file
        local router_pid="" internet_pid=""

        tmpdir=$(mktemp -d) || return
        router_file="$tmpdir/router"
        internet_file="$tmpdir/internet"

        if [[ -n $gateway ]]; then
          ping_latency_ms "$gateway" >"$router_file" &
          router_pid=$!
        fi

        ping_latency_ms "$internet_probe" >"$internet_file" &
        internet_pid=$!

        if [[ -n $router_pid ]]; then
          wait "$router_pid"
          printf 'router_ping_ms\t%s\n' "$(cat "$router_file")"
        fi

        wait "$internet_pid"
        printf 'internet_ping_ms\t%s\n' "$(cat "$internet_file")"
        rm -rf "$tmpdir"
      }

      print_verbose() {
        local route_json iface gw src prefix link

        route_json=$(ip -j route get "$internet_probe" 2>/dev/null)
        [[ -z $route_json ]] && return

        iface=$(jq -r '.[0].dev // ""' <<<"$route_json" 2>/dev/null)
        gw=$(jq -r '.[0].gateway // ""' <<<"$route_json" 2>/dev/null)
        src=$(jq -r '.[0].prefsrc // ""' <<<"$route_json" 2>/dev/null)

        [[ -z $iface ]] && return

        prefix=$(ip -j addr show "$iface" 2>/dev/null | jq -r '.[0].addr_info[]? | select(.family == "inet") | .prefixlen // ""' 2>/dev/null | head -n 1)

        printf 'iface\t%s\n' "$iface"
        printf 'ip\t%s\n' "$src"
        printf 'prefix\t%s\n' "$prefix"
        printf 'gateway\t%s\n' "$gw"

        if [[ -r /sys/class/net/$iface/statistics/rx_bytes ]]; then
          printf 'rx_bytes\t%s\n' "$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
        fi
        if [[ -r /sys/class/net/$iface/statistics/tx_bytes ]]; then
          printf 'tx_bytes\t%s\n' "$(cat "/sys/class/net/$iface/statistics/tx_bytes")"
        fi

        if [[ -d /sys/class/net/$iface/wireless ]]; then
          printf 'type\twifi\n'

          link=$(iw dev "$iface" link 2>/dev/null)

          if [[ -n $link ]]; then
            printf 'ssid\t%s\n' "$(awk '/SSID:/ { sub(/.*SSID: /, ""); print; exit }' <<<"$link")"
            printf 'signal_dbm\t%s\n' "$(awk '/signal:/ { print $2; exit }' <<<"$link")"
            printf 'freq\t%s\n' "$(awk '/freq:/ { print $2; exit }' <<<"$link")"
            printf 'bitrate\t%s %s\n' "$(awk '/tx bitrate:/ { print $3; exit }' <<<"$link")" "$(awk '/tx bitrate:/ { print $4; exit }' <<<"$link")"
          fi
        else
          printf 'type\tethernet\n'
          [[ -r /sys/class/net/$iface/speed ]] && printf 'speed\t%s\n' "$(cat "/sys/class/net/$iface/speed")"
          [[ -r /sys/class/net/$iface/duplex ]] && printf 'duplex\t%s\n' "$(cat "/sys/class/net/$iface/duplex")"
        fi

        print_ping_samples "$gw"
      }

      if [[ $verbose == "true" ]]; then
        print_verbose
      else
        print_status
      fi
    '';
  };

  networkSpeedtest = pkgs.writeShellApplication {
    name = "omarchy-network-speedtest";
    runtimeInputs = [
      pkgs.iproute2
      pkgs.curl
      pkgs.jq
      pkgs.gawk
      pkgs.coreutils
      pkgs.procps
    ];
    # SC2086 fires on `traffic_worker $fast_urls &` -- the unquoted
    # variable is deliberate word-splitting, not a bug: $fast_urls is a
    # newline-separated list from `jq -r`, and leaving it unquoted is
    # exactly what turns it into separate positional args for
    # `traffic_worker "$@"` inside the function (each URL a distinct
    # $1, $2, ... entry it round-robins across). Quoting it would pass
    # the whole multi-line blob as a single argument instead, breaking
    # the round-robin. Confirmed against upstream Omarchy's own script
    # (the source this was ported from) -- same construct there too.
    excludeShellChecks = [ "SC2086" ];
    text = ''
      direction="''${1:-}"
      probe=1.1.1.1
      parallel=8
      url_count=3

      case "$direction" in
        down | up)
          ;;
        *)
          echo "Usage: omarchy-network-speedtest [down|up]" >&2
          exit 2
          ;;
      esac

      format_mbps() {
        awk -v value="$1" 'BEGIN {
          if (value <= 0) print "0.0"
          else if (value < 10) printf "%.1f\n", value
          else printf "%.0f\n", value
        }'
      }

      iface=$(ip route get "$probe" 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')

      if [[ -z $iface || ! -r /sys/class/net/$iface/statistics/rx_bytes || ! -r /sys/class/net/$iface/statistics/tx_bytes ]]; then
        echo "No active network interface" >&2
        exit 1
      fi

      fast_token="YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm"
      fast_api_url="https://api.fast.com/netflix/speedtest/v2?https=true&token=$fast_token&urlCount=$url_count"

      fast_urls=$(curl -fsS "$fast_api_url" 2>/dev/null | jq -r '.targets[]?.url // empty')

      if [[ -z $fast_urls ]]; then
        echo "Failed to fetch speed test endpoints" >&2
        exit 1
      fi

      traffic_pids=()

      cleanup() {
        local pid
        for pid in "''${traffic_pids[@]}"; do
          [[ -n $pid ]] || continue
          pkill -TERM -P "$pid" 2>/dev/null || true
          kill "$pid" 2>/dev/null || true
        done
        for pid in "''${traffic_pids[@]}"; do
          [[ -n $pid ]] || continue
          wait "$pid" 2>/dev/null || true
        done
      }
      trap cleanup EXIT

      # Round-robin across the returned URLs so we spread load across
      # Netflix OCA nodes.
      traffic_worker() {
        local urls=("$@")
        local url_count=''${#urls[@]}
        local idx=$RANDOM
        if [[ $direction == "down" ]]; then
          while true; do
            url=''${urls[$((idx % url_count))]}
            curl -fsS -o /dev/null "$url" 2>/dev/null || return
            idx=$((idx + 1))
          done
        else
          while true; do
            url=''${urls[$((idx % url_count))]}
            dd if=/dev/zero bs=1M count=64 2>/dev/null | curl -fsS -o /dev/null -X POST --data-binary @- "$url" 2>/dev/null || return
            idx=$((idx + 1))
          done
        fi
      }

      for (( i = 0; i < parallel; i++ )); do
        traffic_worker $fast_urls &
        traffic_pids+=("$!")
      done

      rx_before=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
      tx_before=$(cat "/sys/class/net/$iface/statistics/tx_bytes")

      any_alive() {
        local pid
        for pid in "''${traffic_pids[@]}"; do
          [[ -n $pid ]] || continue
          if kill -0 "$pid" 2>/dev/null; then
            return 0
          fi
        done
        return 1
      }

      while any_alive; do
        sleep 1
        rx_after=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
        tx_after=$(cat "/sys/class/net/$iface/statistics/tx_bytes")

        if [[ $direction == "down" ]]; then
          rate=$(awk -v before="$rx_before" -v after="$rx_after" 'BEGIN {
            if (after < before) print 0
            else print (after - before) * 8 / 1000000
          }')
        else
          rate=$(awk -v before="$tx_before" -v after="$tx_after" 'BEGIN {
            if (after < before) print 0
            else print (after - before) * 8 / 1000000
          }')
        fi

        format_mbps "$rate"
        rx_before=$rx_after
        tx_before=$tx_after
      done

      wait 2>/dev/null || true
    '';
  };
in
{
  home.packages = [
    networkStatus
    networkSpeedtest
  ];
}
