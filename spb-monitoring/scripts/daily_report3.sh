#!/bin/bash

PROMETHEUS_URL="http://localhost:9090"
TELEGRAM_BOT_TOKEN="hidden"
TELEGRAM_CHAT_ID="-hidden"

get_prometheus_data() {
    local query="$1"
    curl -s -G --data-urlencode "query=$query" "$PROMETHEUS_URL/api/v1/query" | jq -r '.data.result[0].value[1]'
}

convert_to_hours() {
    echo "scale=2; $1 / 3600" | bc
}

# Аптайм
uptime_local_seconds=$(get_prometheus_data 'time() - node_boot_time_seconds{job="local-node"}')
uptime_helsinki_seconds=$(get_prometheus_data 'time() - node_boot_time_seconds{job="helsinki-node"}')
uptime_germany_seconds=$(get_prometheus_data 'time() - node_boot_time_seconds{job="germany-node"}')
uptime_pve_seconds=$(get_prometheus_data 'time() - node_boot_time_seconds{job="pve-spb-cctv-aivm"}')
uptime_amsterdam_seconds=$(get_prometheus_data 'time() - node_boot_time_seconds{job="germany-node-sbg"}')


# CPU
cpu_local=$(get_prometheus_data '100 - (avg by (instance) (irate(node_cpu_seconds_total{job="local-node", mode="idle"}[5m])) * 100)')
cpu_helsinki=$(get_prometheus_data '100 - (avg by (instance) (irate(node_cpu_seconds_total{job="helsinki-node", mode="idle"}[5m])) * 100)')
cpu_germany=$(get_prometheus_data '100 - (avg by (instance) (irate(node_cpu_seconds_total{job="germany-node", mode="idle"}[5m])) * 100)')
cpu_amsterdam=$(get_prometheus_data '100 - (avg by (instance) (irate(node_cpu_seconds_total{job="germany-node-sbg", mode="idle"}[5m])) * 100)')
cpu_pve=$(get_prometheus_data '100 - (avg by (instance) (irate(node_cpu_seconds_total{job="pve-spb-cctv-aivm", mode="idle"}[5m])) * 100)')
# RAM
ram_local=$(get_prometheus_data '100 * (node_memory_MemTotal_bytes{job="local-node"} - node_memory_MemFree_bytes{job="local-node"} - node_memory_Buffers_bytes{job="local-node"} - node_memory_Cached_bytes{job="local-node"}) / node_memory_MemTotal_bytes{job="local-node"}')
ram_helsinki=$(get_prometheus_data '100 * (node_memory_MemTotal_bytes{job="helsinki-node"} - node_memory_MemFree_bytes{job="helsinki-node"} - node_memory_Buffers_bytes{job="helsinki-node"} - node_memory_Cached_bytes{job="helsinki-node"}) / node_memory_MemTotal_bytes{job="helsinki-node"}')
ram_germany=$(get_prometheus_data '100 * (node_memory_MemTotal_bytes{job="germany-node"} - node_memory_MemFree_bytes{job="germany-node"} - node_memory_Buffers_bytes{job="germany-node"} - node_memory_Cached_bytes{job="germany-node"}) / node_memory_MemTotal_bytes{job="germany-node"}')
ram_amsterdam=$(get_prometheus_data '100 * (node_memory_MemTotal_bytes{job="germany-node-sbg"} - node_memory_MemFree_bytes{job="germany-node-sbg"} - node_memory_Buffers_bytes{job="germany-node-sbg"} - node_memory_Cached_bytes{job="germany-node-sbg"}) / node_memory_MemTotal_bytes{job="germany-node-sbg"}')
ram_pve=$(get_prometheus_data '100 * (node_memory_MemTotal_bytes{job="pve-spb-cctv-aivm"} - node_memory_MemFree_bytes{job="pve-spb-cctv-aivm"} - node_memory_Buffers_bytes{job="pve-spb-cctv-aivm"} - node_memory_Cached_bytes{job="pve-spb-cctv-aivm"}) / node_memory_MemTotal_bytes{job="pve-spb-cctv-aivm"}')
# Disk
disk_local=$(get_prometheus_data '100 * (node_filesystem_size_bytes{job="local-node",fstype!="tmpfs",fstype!="overlay"} - node_filesystem_free_bytes{job="local-node",fstype!="tmpfs",fstype!="overlay"}) / node_filesystem_size_bytes{job="local-node",fstype!="tmpfs",fstype!="overlay"}')
disk_helsinki=$(get_prometheus_data '100 * (node_filesystem_size_bytes{job="helsinki-node",fstype!="tmpfs",fstype!="overlay"} - node_filesystem_free_bytes{job="helsinki-node",fstype!="tmpfs",fstype!="overlay"}) / node_filesystem_size_bytes{job="helsinki-node",fstype!="tmpfs",fstype!="overlay"}')
disk_germany=$(get_prometheus_data '100 * (node_filesystem_size_bytes{job="germany-node",fstype!="tmpfs",fstype!="overlay"} - node_filesystem_free_bytes{job="germany-node",fstype!="tmpfs",fstype!="overlay"}) / node_filesystem_size_bytes{job="germany-node",fstype!="tmpfs",fstype!="overlay"}')
disk_amsterdam=$(get_prometheus_data '100 * (node_filesystem_size_bytes{job="germany-node-sbg",fstype!="tmpfs",fstype!="overlay"} - node_filesystem_free_bytes{job="germany-node-sbg",fstype!="tmpfs",fstype!="overlay"}) / node_filesystem_size_bytes{job="germany-node-sbg",fstype!="tmpfs",fstype!="overlay"}')
disk_pve=$(get_prometheus_data '100 * (node_filesystem_size_bytes{job="pve-spb-cctv-aivm",fstype!="tmpfs",fstype!="overlay"} - node_filesystem_free_bytes{job="pve-spb-cctv-aivm",fstype!="tmpfs",fstype!="overlay"}) / node_filesystem_size_bytes{job="pve-spb-cctv-aivm",fstype!="tmpfs",fstype!="overlay"}')
# Traffic за сутки
traffic_local=$(get_prometheus_data 'delta(node_network_receive_bytes_total{job="local-node", device="eth0"}[24h]) + delta(node_network_transmit_bytes_total{job="local-node", device="eth0"}[24h])')
traffic_helsinki=$(get_prometheus_data 'delta(node_network_receive_bytes_total{job="helsinki-node", device="ens3"}[24h]) + delta(node_network_transmit_bytes_total{job="helsinki-node", device="ens3"}[24h])')
traffic_germany=$(get_prometheus_data 'delta(node_network_receive_bytes_total{job="germany-node", device="eth0"}[24h]) + delta(node_network_transmit_bytes_total{job="germany-node", device="eth0"}[24h])')
traffic_amsterdam=$(get_prometheus_data 'delta(node_network_receive_bytes_total{job="germany-node-sbg", device="eth0"}[24h]) + delta(node_network_transmit_bytes_total{job="germany-node-sbg", device="eth0"}[24h])')
traffic_pve=$(get_prometheus_data 'delta(node_network_receive_bytes_total{job="pve-spb-cctv-aivm", device="enp6s18"}[24h]) + delta(node_network_transmit_bytes_total{job="pve-spb-cctv-aivm", device="enp6s18"}[24h])')
# Общий трафик (с момента старта) в байтах
total_traffic_local=$(get_prometheus_data 'node_network_receive_bytes_total{job="local-node", device="eth0"} + node_network_transmit_bytes_total{job="local-node", device="eth0"}')
total_traffic_helsinki=$(get_prometheus_data 'node_network_receive_bytes_total{job="helsinki-node", device="ens3"} + node_network_transmit_bytes_total{job="helsinki-node", device="ens3"}')
total_traffic_germany=$(get_prometheus_data 'node_network_receive_bytes_total{job="germany-node", device="eth0"} + node_network_transmit_bytes_total{job="germany-node", device="eth0"}')
total_traffic_amsterdam=$(get_prometheus_data 'node_network_receive_bytes_total{job="germany-node-sbg", device="eth0"} + node_network_transmit_bytes_total{job="germany-node-sbg", device="eth0"}')
total_traffic_pve=$(get_prometheus_data 'node_network_receive_bytes_total{job="pve-spb-cctv-aivm", device="enp6s18"} + node_network_transmit_bytes_total{job="pve-spb-cctv-aivm", device="enp6s18"}')
# Форматируем
uptime_local=$(convert_to_hours $uptime_local_seconds)
uptime_helsinki=$(convert_to_hours $uptime_helsinki_seconds)
uptime_germany=$(convert_to_hours $uptime_germany_seconds)
uptime_amsterdam=$(convert_to_hours $uptime_amsterdam_seconds)
uptime_pve=$(convert_to_hours $uptime_pve_seconds)

traffic_local=$(echo "scale=2; $traffic_local/1024/1024/1024" | bc -l)
traffic_helsinki=$(echo "scale=2; $traffic_helsinki/1024/1024/1024" | bc -l)
traffic_germany=$(echo "scale=2; $traffic_germany/1024/1024/1024" | bc -l)
traffic_amsterdam=$(echo "scale=2; $traffic_amsterdam/1024/1024/1024" | bc -l)
traffic_pve=$(echo "scale=2; $traffic_pve/1024/1024/1024" | bc -l)

total_traffic_local=$(echo "scale=2; $total_traffic_local/1024/1024/1024" | bc)
total_traffic_helsinki=$(echo "scale=2; $total_traffic_helsinki/1024/1024/1024" | bc)
total_traffic_germany=$(echo "scale=2; $total_traffic_germany/1024/1024/1024" | bc)
total_traffic_amsterdam=$(echo "scale=2; $total_traffic_amsterdam/1024/1024/1024" | bc)
total_traffic_pve=$(echo "scale=2; $total_traffic_pve/1024/1024/1024" | bc)

# Функция обрезания значений до двух знаков после запятой
trim_to_two_decimal() {
    echo "$1" | awk -F. '{printf "%s.%s", $1, substr($2 "00", 1, 2)}'
}

uptime_local=$(trim_to_two_decimal "$uptime_local")
cpu_local=$(trim_to_two_decimal "$cpu_local")
ram_local=$(trim_to_two_decimal "$ram_local")
disk_local=$(trim_to_two_decimal "$disk_local")
traffic_local=$(trim_to_two_decimal "$traffic_local")
total_traffic_local=$(trim_to_two_decimal "$total_traffic_local")

uptime_helsinki=$(trim_to_two_decimal "$uptime_helsinki")
cpu_helsinki=$(trim_to_two_decimal "$cpu_helsinki")
ram_helsinki=$(trim_to_two_decimal "$ram_helsinki")
disk_helsinki=$(trim_to_two_decimal "$disk_helsinki")
traffic_helsinki=$(trim_to_two_decimal "$traffic_helsinki")
total_traffic_helsinki=$(trim_to_two_decimal "$total_traffic_helsinki")

uptime_germany=$(trim_to_two_decimal "$uptime_germany")
cpu_germany=$(trim_to_two_decimal "$cpu_germany")
ram_germany=$(trim_to_two_decimal "$ram_germany")
disk_germany=$(trim_to_two_decimal "$disk_germany")
traffic_germany=$(trim_to_two_decimal "$traffic_germany")
total_traffic_germany=$(trim_to_two_decimal "$total_traffic_germany")

uptime_amsterdam=$(trim_to_two_decimal "$uptime_amsterdam")
cpu_amsterdam=$(trim_to_two_decimal "$cpu_amsterdam")
ram_amsterdam=$(trim_to_two_decimal "$ram_amsterdam")
disk_amsterdam=$(trim_to_two_decimal "$disk_amsterdam")
traffic_amsterdam=$(trim_to_two_decimal "$traffic_amsterdam")
total_traffic_amsterdam=$(trim_to_two_decimal "$total_traffic_amsterdam")

uptime_pve=$(trim_to_two_decimal "$uptime_pve")
cpu_pve=$(trim_to_two_decimal "$cpu_pve")
ram_pve=$(trim_to_two_decimal "$ram_pve")
disk_pve=$(trim_to_two_decimal "$disk_pve")
traffic_pve=$(trim_to_two_decimal "$traffic_pve")
total_traffic_pve=$(trim_to_two_decimal "$total_traffic_pve")

message="🗓️ $(date +%Y-%m-%d) | Ежедневный инфраструктурный отчёт о ресурсах серверов:


💡 spb-debian-srv
├ 🕰 Аптайм: $uptime_local ч
├ 🧠 CPU: $cpu_local%
├ 💾 RAM: $ram_local%
├ 📂 Disk: $disk_local%
├ 📡 Трафик за сутки: $traffic_local ГБ
└ 📡 Всего трафика: $total_traffic_local ГБ

💡 helsinki-hetzner-endpoint
├ 🕰 Аптайм: $uptime_helsinki ч
├ 🧠 CPU: $cpu_helsinki%
├ 💾 RAM: $ram_helsinki%
├ 📂 Disk: $disk_helsinki%
├ 📡 Трафик за сутки: $traffic_helsinki ГБ
└ 📡 Всего трафика: $total_traffic_helsinki ГБ

💡 fra-xray-lb01
├ 🕰 Аптайм: $uptime_germany ч
├ 🧠 CPU: $cpu_germany%
├ 💾 RAM: $ram_germany%
├ 📂 Disk: $disk_germany%
├ 📡 Трафик за сутки: $traffic_germany ГБ
└ 📡 Всего трафика: $total_traffic_germany ГБ

💡 nl-ams-endpoint
├ 🕰 Аптайм: $uptime_amsterdam ч
├ 🧠 CPU: $cpu_amsterdam%
├ 💾 RAM: $ram_amsterdam%
├ 📂 Disk: $disk_amsterdam%
├ 📡 Трафик за сутки: $traffic_amsterdam ГБ
└ 📡 Всего трафика: $total_traffic_amsterdam ГБ

💡 pve-spb-cctv-ai-videoserver
├ 🕰 Аптайм: $uptime_pve ч
├ 🧠 CPU: $cpu_pve%
├ 💾 RAM: $ram_pve%
├ 📂 Disk: $disk_pve%
├ 📡 Трафик за сутки: $traffic_pve ГБ
└ 📡 Всего трафика: $total_traffic_pve ГБ"

curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID" \
    -d "text=$message" \
    -d "parse_mode=Markdown"
