#!/bin/bash


NTOPNG_URL="http://localhost:3000"
INTERFACE_ID="2"
TELEGRAM_BOT_TOKEN="hidden"
TELEGRAM_CHAT_ID="hidden"

# ===== ПОЛУЧИТЬ ВСЕ ДАННЫЕ =====
echo "Сбор данных из ntopng..."

IFACE=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/interface/data.lua?ifid=$INTERFACE_ID")
APPS=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/interface/l7/data.lua?ifid=$INTERFACE_ID")
TOP_HOSTS=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/interface/top/hosts.lua?ifid=$INTERFACE_ID")
ACTIVE=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/host/active.lua?ifid=$INTERFACE_ID")
ASN=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/asn/get_top_asn.lua?ifid=$INTERFACE_ID")
GEO=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/geo_map/hosts.lua?ifid=$INTERFACE_ID")
CATEGORIES=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/category/list.lua")
NETWORKS=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/network/networks_stats.lua?ifid=$INTERFACE_ID")
HEALTH=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/system/health/stats.lua")
STATUS=$(curl -s "$NTOPNG_URL/lua/rest/v2/get/system/status.lua")

# ===== INTERFACE STATS =====
IF_NAME=$(echo "$IFACE" | jq -r '.rsp.ifname')
TOTAL_BYTES=$(echo "$IFACE" | jq -r '.rsp.bytes')
NUM_HOSTS=$(echo "$IFACE" | jq -r '.rsp.num_hosts')
NUM_FLOWS=$(echo "$IFACE" | jq -r '.rsp.num_flows')
NUM_DEVICES=$(echo "$IFACE" | jq -r '.rsp.num_devices')
THROUGHPUT=$(echo "$IFACE" | jq -r '.rsp.throughput_bps')
TCP_RETRANS=$(echo "$IFACE" | jq -r '.rsp.tcpPacketStats.retransmissions')
TCP_LOST=$(echo "$IFACE" | jq -r '.rsp.tcpPacketStats.lost')
ENGAGED_ALERTS=$(echo "$IFACE" | jq -r '.rsp.engaged_alerts // 0')
ENGAGED_ERR=$(echo "$IFACE" | jq -r '.rsp.engaged_alerts_error // 0')
ENGAGED_WARN=$(echo "$IFACE" | jq -r '.rsp.engaged_alerts_warning // 0')
ALERTED_FLOWS=$(echo "$IFACE" | jq -r '.rsp.alerted_flows // 0')

# Форматируем
THROUGHPUT_MBPS=$(echo "scale=1; $THROUGHPUT / 1000 / 1000" | bc 2>/dev/null || echo "0")
TOTAL_GB=$(echo "scale=2; $TOTAL_BYTES / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

# ===== TOP 5 APPLICATIONS =====
TOP_APPS=$(echo "$APPS" | jq -r '.rsp[]? | select(.bytes.total > 0) | "\(.application.name),\(.tot_num_flows),\(.bytes.total),\(.bytes.percentage),\(.breed)"' | sort -t',' -k4 -rn | head -5)

APP1=$(echo "$TOP_APPS" | head -1 | cut -d',' -f1)
APP1_FLOWS=$(echo "$TOP_APPS" | head -1 | cut -d',' -f2)
APP1_PCT=$(echo "$TOP_APPS" | head -1 | cut -d',' -f4)
APP1_BREED=$(echo "$TOP_APPS" | head -1 | cut -d',' -f5)

APP2=$(echo "$TOP_APPS" | head -2 | tail -1 | cut -d',' -f1)
APP2_FLOWS=$(echo "$TOP_APPS" | head -2 | tail -1 | cut -d',' -f2)
APP2_PCT=$(echo "$TOP_APPS" | head -2 | tail -1 | cut -d',' -f4)

APP3=$(echo "$TOP_APPS" | head -3 | tail -1 | cut -d',' -f1)
APP3_FLOWS=$(echo "$TOP_APPS" | head -3 | tail -1 | cut -d',' -f2)
APP3_PCT=$(echo "$TOP_APPS" | head -3 | tail -1 | cut -d',' -f4)

APP4=$(echo "$TOP_APPS" | head -4 | tail -1 | cut -d',' -f1)
APP4_FLOWS=$(echo "$TOP_APPS" | head -4 | tail -1 | cut -d',' -f2)
APP4_PCT=$(echo "$TOP_APPS" | head -4 | tail -1 | cut -d',' -f4)

APP5=$(echo "$TOP_APPS" | head -5 | tail -1 | cut -d',' -f1)
APP5_FLOWS=$(echo "$TOP_APPS" | head -5 | tail -1 | cut -d',' -f2)
APP5_PCT=$(echo "$TOP_APPS" | head -5 | tail -1 | cut -d',' -f4)

# ===== TOP 3 HOSTS =====
HOST1=$(echo "$TOP_HOSTS" | jq -r '.rsp[0].label')
HOST1_BYTES=$(echo "$TOP_HOSTS" | jq -r '.rsp[0].value')
HOST1_GB=$(echo "scale=2; $HOST1_BYTES / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
TOTAL_BYTES_H=$(echo "$TOP_HOSTS" | jq -r '.rsp | map(.value) | add')
HOST1_PCT=$(echo "scale=1; ($HOST1_BYTES * 100) / $TOTAL_BYTES_H" | bc 2>/dev/null || echo "0")

HOST2=$(echo "$TOP_HOSTS" | jq -r '.rsp[1].label')
HOST2_BYTES=$(echo "$TOP_HOSTS" | jq -r '.rsp[1].value')
HOST2_GB=$(echo "scale=2; $HOST2_BYTES / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
HOST2_PCT=$(echo "scale=1; ($HOST2_BYTES * 100) / $TOTAL_BYTES_H" | bc 2>/dev/null || echo "0")

HOST3=$(echo "$TOP_HOSTS" | jq -r '.rsp[2].label')
HOST3_BYTES=$(echo "$TOP_HOSTS" | jq -r '.rsp[2].value')
HOST3_GB=$(echo "scale=2; $HOST3_BYTES / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
HOST3_PCT=$(echo "scale=1; ($HOST3_BYTES * 100) / $TOTAL_BYTES_H" | bc 2>/dev/null || echo "0")

# ===== TOP 3 ASN =====
TOP_ASN=$(echo "$ASN" | jq -r '.rsp[0].asname')
TOP_ASN_NUM=$(echo "$ASN" | jq -r '.rsp[0].asn')
TOP_ASN_BYTES=$(echo "$ASN" | jq -r '(.rsp[0]."bytes.sent" // 0) + (.rsp[0]."bytes.rcvd" // 0)')
TOP_ASN_ALERTS=$(echo "$ASN" | jq -r '.rsp[0]."alerted_flows.total" // 0')
TOP_ASN_SCORE=$(echo "$ASN" | jq -r '.rsp[0].score // 0')
TOP_ASN_GB=$(echo "scale=2; $TOP_ASN_BYTES / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

ASN2_NAME=$(echo "$ASN" | jq -r '.rsp[1].asname')
ASN2_NUM=$(echo "$ASN" | jq -r '.rsp[1].asn')
ASN2_ALERTS=$(echo "$ASN" | jq -r '.rsp[1]."alerted_flows.total" // 0')
ASN2_SCORE=$(echo "$ASN" | jq -r '.rsp[1].score // 0')

ASN3_NAME=$(echo "$ASN" | jq -r '.rsp[2].asname')
ASN3_NUM=$(echo "$ASN" | jq -r '.rsp[2].asn')
ASN3_ALERTS=$(echo "$ASN" | jq -r '.rsp[2]."alerted_flows.total" // 0')

# ===== TOP COUNTRIES =====
GEO_DATA=$(echo "$GEO" | jq -r '.rsp[]? | "\(.country),\(.country_code),\(.city),\(.scoreClient + .scoreServer),\(.numAlerts)"' | sort -u | head -5)

COUNTRY1=$(echo "$GEO_DATA" | head -1 | cut -d',' -f1)
COUNTRY1_CODE=$(echo "$GEO_DATA" | head -1 | cut -d',' -f2)
COUNTRY1_CITY=$(echo "$GEO_DATA" | head -1 | cut -d',' -f3)
COUNTRY1_SCORE=$(echo "$GEO_DATA" | head -1 | cut -d',' -f4)
COUNTRY1_ALERTS=$(echo "$GEO_DATA" | head -1 | cut -d',' -f5)

COUNTRY2=$(echo "$GEO_DATA" | head -2 | tail -1 | cut -d',' -f1)
COUNTRY2_ALERTS=$(echo "$GEO_DATA" | head -2 | tail -1 | cut -d',' -f5)

COUNTRY3=$(echo "$GEO_DATA" | head -3 | tail -1 | cut -d',' -f1)
COUNTRY3_ALERTS=$(echo "$GEO_DATA" | head -3 | tail -1 | cut -d',' -f5)

# ===== TOP CATEGORIES =====
TOP_CATS=$(echo "$CATEGORIES" | jq -r '.rsp[]? | select(.column_num_protos > "0") | "\(.column_category_name),\(.column_num_protos),\(.column_num_hosts)"' | sort -t',' -k2 -rn | head -5)

CAT1=$(echo "$TOP_CATS" | head -1 | cut -d',' -f1)
CAT1_PROTOS=$(echo "$TOP_CATS" | head -1 | cut -d',' -f2)

CAT2=$(echo "$TOP_CATS" | head -2 | tail -1 | cut -d',' -f1)
CAT2_PROTOS=$(echo "$TOP_CATS" | head -2 | tail -1 | cut -d',' -f2)

CAT3=$(echo "$TOP_CATS" | head -3 | tail -1 | cut -d',' -f1)
CAT3_PROTOS=$(echo "$TOP_CATS" | head -3 | tail -1 | cut -d',' -f2)

# ===== SYSTEM HEALTH =====
RAM_USED=$(echo "$HEALTH" | jq -r '.mem_used // 0' | head -c 20)
RAM_TOTAL=$(echo "$HEALTH" | jq -r '.mem_total // 0' | head -c 20)

if [ -z "$RAM_TOTAL" ] || [ "$RAM_TOTAL" = "null" ] || [ "$RAM_TOTAL" -eq 0 ] 2>/dev/null; then
    RAM_USED_PCT=0
else
    RAM_USED_PCT=$(echo "$RAM_USED * 100 / $RAM_TOTAL" | bc 2>/dev/null || echo "0")
fi

CPU_IDLE=$(echo "$HEALTH" | jq -r '.cpu_states.idle_percentage // 0' | head -c 10)
CPU_USER=$(echo "$HEALTH" | jq -r '.cpu_states.user // 0' | head -c 10)
CPU_SYSTEM=$(echo "$HEALTH" | jq -r '.cpu_states.system // 0' | head -c 10)
NTOPNG_MEM=$(echo "$HEALTH" | jq -r '.mem_ntopng_resident // 0')
ALERTS_QUEUE=$(echo "$HEALTH" | jq -r '.alerts_queries // 0')
RRD_STORAGE=$(echo "$HEALTH" | jq -r '.storage.interfaces[1].rrd // 0')
RRD_GB=$(echo "scale=2; $RRD_STORAGE / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

# ===== STATUS =====
VERSION=$(echo "$STATUS" | jq -r '.rsp.license_info.version // "Unknown"' | head -c 50)
LICENSE=$(echo "$STATUS" | jq -r '.rsp.license_info.status // "Unknown"')

# ===== ACTIVE HOSTS TOP 3 =====
ACTIVE_HOSTS=$(echo "$ACTIVE" | jq -r '.rsp.data[]? | "\(.ip),\(.country),\(.bytes.total),\(.score.total),\(.num_alerts),\(.is_blacklisted)"' | sort -t',' -k3 -rn | head -3)

AH1=$(echo "$ACTIVE_HOSTS" | head -1 | cut -d',' -f1)
AH1_COUNTRY=$(echo "$ACTIVE_HOSTS" | head -1 | cut -d',' -f2)
AH1_SCORE=$(echo "$ACTIVE_HOSTS" | head -1 | cut -d',' -f4)
AH1_ALERTS=$(echo "$ACTIVE_HOSTS" | head -1 | cut -d',' -f5)

AH2=$(echo "$ACTIVE_HOSTS" | head -2 | tail -1 | cut -d',' -f1)
AH2_COUNTRY=$(echo "$ACTIVE_HOSTS" | head -2 | tail -1 | cut -d',' -f2)

AH3=$(echo "$ACTIVE_HOSTS" | head -3 | tail -1 | cut -d',' -f1)
AH3_COUNTRY=$(echo "$ACTIVE_HOSTS" | head -3 | tail -1 | cut -d',' -f2)

# ===== NETWORK STATS =====
NET_STATS=$(echo "$NETWORKS" | jq -r '.rsp[]? | "\(.networkName),\(.hosts),\(.traffic),\(.alertedFlows)"' | head -3)

NET1=$(echo "$NET_STATS" | head -1 | cut -d',' -f1)
NET1_HOSTS=$(echo "$NET_STATS" | head -1 | cut -d',' -f2)
NET1_TRAFFIC=$(echo "$NET_STATS" | head -1 | cut -d',' -f3)
NET1_ALERTS=$(echo "$NET_STATS" | head -1 | cut -d',' -f4)

# ===== ALERT STATUS =====
ENGAGED_ALERTS_INT=$(echo "${ENGAGED_ALERTS%.*}" | tr -d '\n' | head -c 10)
if [ -z "$ENGAGED_ALERTS_INT" ]; then ENGAGED_ALERTS_INT=0; fi

if [ "$ENGAGED_ALERTS_INT" -gt 100 ] 2>/dev/null; then
    ALERT_EMOJI="🔴"
    ALERT_TEXT="КРИТИЧНО"
elif [ "$ENGAGED_ALERTS_INT" -gt 50 ] 2>/dev/null; then
    ALERT_EMOJI="🟠"
    ALERT_TEXT="ВЫСОКИЙ"
elif [ "$ENGAGED_ALERTS_INT" -gt 10 ] 2>/dev/null; then
    ALERT_EMOJI="🟡"
    ALERT_TEXT="СРЕДНИЙ"
else
    ALERT_EMOJI="🟢"
    ALERT_TEXT="НОРМАЛЬНО"
fi

RAM_PCT_INT=$(echo "$RAM_USED_PCT" | tr -d '\n' | head -c 3)
if [ -z "$RAM_PCT_INT" ]; then RAM_PCT_INT=0; fi

if [ "$RAM_PCT_INT" -gt 80 ] 2>/dev/null; then
    RAM_EMOJI="🔴"
elif [ "$RAM_PCT_INT" -gt 70 ] 2>/dev/null; then
    RAM_EMOJI="🟠"
elif [ "$RAM_PCT_INT" -gt 50 ] 2>/dev/null; then
    RAM_EMOJI="🟡"
else
    RAM_EMOJI="🟢"
fi

CPU_ACTIVE=$(echo "scale=0; 100 - $CPU_IDLE" | bc 2>/dev/null || echo "0")
CPU_ACTIVE_INT=$(echo "${CPU_ACTIVE%.*}" | tr -d '\n' | head -c 3)
if [ -z "$CPU_ACTIVE_INT" ]; then CPU_ACTIVE_INT=0; fi

if [ "$CPU_ACTIVE_INT" -gt 80 ] 2>/dev/null; then
    CPU_EMOJI="🔴"
elif [ "$CPU_ACTIVE_INT" -gt 60 ] 2>/dev/null; then
    CPU_EMOJI="🟠"
else
    CPU_EMOJI="🟢"
fi

# ===== BUILD MESSAGE =====
message="💡 ЕЖЕДНЕВНЫЙ ОТЧЁТ СИСТЕМЫ DPI ENDPOINT В ОСЛО, НОРВЕГИЯ
🕐 Дата: $(date '+%d.%m.%Y %H:%M:%S')

-------------------------------------------
💡 СТАТИСТИКА ИНТЕРФЕЙСА eth0
-------------------------------------------

🌐 Трафик: $TOTAL_GB ГБ
📊 Хостов активно: $NUM_HOSTS
📡 Потоков: $NUM_FLOWS
👾 Устройств: $NUM_DEVICES
🎮 Текущий throughput: $THROUGHPUT_MBPS Mbps
⛔ TCP переадреса: $TCP_RETRANS
💥 Потеряных пакетов: $TCP_LOST

-------------------------------------------
💡 ТОП ПРИЛОЖЕНИЙ (L7 Classification)
-------------------------------------------

🏅 #1 $APP1 ($APP1_BREED)
   Потоков: $APP1_FLOWS
   Трафик: $APP1_PCT%

🥈 #2 $APP2
   Потоков: $APP2_FLOWS
   Трафик: $APP2_PCT%

🥉 #3 $APP3
   Потоков: $APP3_FLOWS
   Трафик: $APP3_PCT%

4️⃣  #4 $APP4
   Потоков: $APP4_FLOWS | Трафик: $APP4_PCT%

5️⃣  #5 $APP5
   Потоков: $APP5_FLOWS | Трафик: $APP5_PCT%

-------------------------------------------
💡 ТОП ХОСТЫ ПО ТРАФИКУ
-------------------------------------------

🏅 #1 $HOST1
   Трафик: $HOST1_GB ГБ
   Доля: $HOST1_PCT%

🥈 #2 $HOST2
   Трафик: $HOST2_GB ГБ
   Доля: $HOST2_PCT%

🥉 #3 $HOST3
   Трафик: $HOST3_GB ГБ
   Доля: $HOST3_PCT%

-------------------------------------------
💡 ТОП AUTONOMOUS SYSTEMS (ASN)
-------------------------------------------

🏅 AS$TOP_ASN_NUM: $TOP_ASN
Трафик: $TOP_ASN_GB ГБ | Score: $TOP_ASN_SCORE | Алертов: $TOP_ASN_ALERTS

🥈 AS$ASN2_NUM: $ASN2_NAME
Score: $ASN2_SCORE | Алертов: $ASN2_ALERTS

🥉 AS$ASN3_NUM: $ASN3_NAME
Алертов: $ASN3_ALERTS

-------------------------------------------
💡 ГЕОГРАФИЯ - ТОП СТРАНЫ
-------------------------------------------

🌍 1. $COUNTRY1 ($COUNTRY1_CODE) - $COUNTRY1_CITY
   Score: $COUNTRY1_SCORE
   Алертов: $COUNTRY1_ALERTS

🌎 2. $COUNTRY2
   Алертов: $COUNTRY2_ALERTS

🌏 3. $COUNTRY3
   Алертов: $COUNTRY3_ALERTS

-------------------------------------------
💡 АКТИВНЫЕ ХОСТЫ (РИСК)
-------------------------------------------

📍 1. $AH1 ($AH1_COUNTRY)
   Score: $AH1_SCORE
   Алертов: $AH1_ALERTS

📍 2. $AH2 ($AH2_COUNTRY)

📍 3. $AH3 ($AH3_COUNTRY)

-------------------------------------------
💡 КАТЕГОРИИ ПРИЛОЖЕНИЙ
-------------------------------------------

📂 $CAT1: $CAT1_PROTOS протоколов
📂 $CAT2: $CAT2_PROTOS протоколов
📂 $CAT3: $CAT3_PROTOS протоколов

-------------------------------------------
💡 БЕЗОПАСНОСТЬ И АЛЕРТЫ
-------------------------------------------

$ALERT_EMOJI Статус алертов: $ALERT_TEXT
   Всего задействованых: $ENGAGED_ALERTS
   Ошибок (ERROR): $ENGAGED_ERR
   Предупреждений (WARNING): $ENGAGED_WARN
   Потоков с алертами: $ALERTED_FLOWS

📋 Очередь алертов: $ALERTS_QUEUE

-------------------------------------------
💡 ЗДОРОВЬЕ СИСТЕМЫ
-------------------------------------------

$CPU_EMOJI CPU Active: $CPU_ACTIVE_INT%
   User: $CPU_USER% | System: $CPU_SYSTEM% | Idle: $CPU_IDLE%

$RAM_EMOJI RAM: $RAM_USED_PCT%
   Используется: $RAM_USED KB
   Всего: $RAM_TOTAL KB
   ntopng процесс: $NTOPNG_MEM KB

💾 RRD Storage: $RRD_GB ГБ

-------------------------------------------
💡 СЕТИ И ТОПОЛОГИЯ
-------------------------------------------

🔗 $NET1
Хостов: $NET1_HOSTS | Трафик: $NET1_TRAFFIC bytes | Алертов: $NET1_ALERTS

-------------------------------------------
💡 ИНФОРМАЦИЯ О СИСТЕМЕ
-------------------------------------------

📌 Версия: $VERSION
📜 Лицензия: $LICENSE
🔧 Статус: Активна и мониторится
✅ Последнее обновление: $(date '+%Y-%m-%d %H:%M:%S')"

# ===== ОТПРАВИТЬ В TELEGRAM =====
echo "Отправка отчёта в Telegram..."

curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID" \
    -d "text=$message"

echo ""
echo "Отчёт отправлен!"
