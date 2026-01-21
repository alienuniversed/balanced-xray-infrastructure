# SPB Monitoring Server

Centralized monitoring, metrics collection, and alerting server located in Saint Petersburg.

## Role

Central hub for all infrastructure monitoring, metrics aggregation, visualization, and alerting.

## Services

- **Prometheus** - Metrics collection and storage (port 9090)
- **Grafana** - Visualization and dashboards (port 3000)
- **Alertmanager** - Alert routing and notifications (port 9093)
- **Telegram Bot Integration** - Alert delivery
- **Custom Metric Collectors** - Tunnel statistics and custom metrics

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              SPB Monitoring Server                  │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐│
│  │  Prometheus  │  │   Grafana    │  │Alertmanager││
│  │   :9090      │◄─┤   :3000      │◄─┤   :9093    ││
│  └──────┬───────┘  └──────────────┘  └─────┬──────┘│
│         │                                   │       │
│         │ Scrapes                          │       │
│         ▼                                   ▼       │
│  ┌──────────────────────────────────────────────┐  │
│  │         Monitored Targets                    │  │
│  │  • Germany LB (Node, cAdvisor, HAProxy)     │  │
│  │  • Oslo (Node, cAdvisor, NTOP)              │  │
│  │  • Amsterdam (Node, cAdvisor, NTOP)         │  │
│  │  • SPB AI Videoserver (Node, cAdvisor)      │  │
│  │  • Proxmox (PVE Exporter)                   │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │         Custom Scripts                       │  │
│  │  • daily_report_tun_last.sh                 │  │
│  │  • Tunnel bandwidth collectors               │  │
│  │  • Traffic analysis scripts                  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│                        │                            │
│                        ▼                            │
│              ┌──────────────────┐                  │
│              │  Telegram Bot    │                  │
│              │  Notifications   │                  │
│              └──────────────────┘                  │
└─────────────────────────────────────────────────────┘
```

## Configuration Files

### `configs/prometheus.yml.example`

Prometheus scrape configuration for all infrastructure components.

**Scrape jobs:**
- `local-node` - SPB server itself
- `germany-node` - Germany load balancer
- `nw-oslo-node` - Oslo endpoint
- `ntopng-oslo` - Oslo NTOP exporter
- `ntopng-amsterdam` - Amsterdam NTOP exporter
- `haproxy` - HAProxy metrics
- `cadvisor` - All cAdvisor instances
- `pve_exporter` - Proxmox metrics
- `pve-spb-cctv-aivm` - AI video server

**Before use:**
1. Copy to `prometheus.yml`
2. Replace `hidden` placeholders with actual IPs:
   - Germany LB internal IP
   - Oslo: 10.0.0.5
   - Amsterdam: 10.0.0.2
   - SPB internal IPs

### `configs/alertmanager.yml`

Alert routing configuration.

**Features:**
- Route alerts to Telegram
- Group similar alerts
- Silence/inhibition rules
- Repeat interval configuration

**Configure:**
```yaml
receivers:
  - name: 'telegram'
    webhook_configs:
      - url: 'http://telegram-bot:8080/alert'
        send_resolved: true
```

### `configs/alert.rules.yml`

Prometheus alert rules.

**Default alerts:**
- High CPU usage (>80% for 5 min)
- High memory usage (>90%)
- Disk space low (<10% free)
- Service down
- High error rate

**Add custom alerts:**
```yaml
- alert: HighTunnelLatency
  expr: wireguard_latest_handshake_seconds > 300
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "WireGuard tunnel {{ $labels.interface }} has high latency"
```

### `configs/monitoring-docker-compose.yml`

Docker Compose stack for Prometheus, Grafana, Alertmanager.

**Services:**
- Prometheus with persistent volume
- Grafana with pre-configured datasources
- Alertmanager with config reload

## Deployment

### 1. Prepare Environment

```bash
# Create directory structure
mkdir -p /opt/monitoring/{prometheus-data,grafana-data,alertmanager-data}

# Set permissions
chown -R 65534:65534 /opt/monitoring/prometheus-data
chown -R 472:472 /opt/monitoring/grafana-data
```

### 2. Configure Prometheus

```bash
# Copy and edit config
cp configs/prometheus.yml.example configs/prometheus.yml
nano configs/prometheus.yml

# Replace 'hidden' with actual IPs
# Verify targets are reachable from monitoring server
```

### 3. Configure Alertmanager

```bash
# Edit alertmanager.yml
nano configs/alertmanager.yml

# Set Telegram bot webhook URL
# Configure alert grouping and routing
```

### 4. Start Stack

```bash
cd /opt/monitoring
cp /path/to/monitoring-docker-compose.yml docker-compose.yml

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f prometheus
docker-compose logs -f grafana
docker-compose logs -f alertmanager
```

### 5. Access Grafana

```bash
# Grafana is accessible at http://<spb-server>:3000
# Default login: admin / admin
# Change password on first login!
```

### 6. Import Dashboards

```bash
# Import pre-built dashboards:
# 1. Node Exporter Full (ID: 1860)
# 2. cAdvisor (ID: 14282)
# 3. HAProxy 2 Full (ID: 12693)
# 4. WireGuard Dashboard (custom - create based on metrics)
```

### 7. Deploy Custom Scripts

```bash
# Copy scripts
mkdir -p /opt/scripts
cp scripts/*.sh /opt/scripts/
chmod +x /opt/scripts/*.sh

# Configure credentials
nano /opt/scripts/daily_report_tun_last.sh
# Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID

# Add to crontab
crontab -e
# Add: 0 9 * * * /opt/scripts/daily_report_tun_last.sh
```

## Verification

### Check Prometheus Targets

```bash
# Via API
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Via web UI
# http://<spb-server>:9090/targets

# All targets should show: state=up
```

### Check Grafana

```bash
# Test Grafana API
curl -u admin:admin http://localhost:3000/api/health

# Access web UI
# http://<spb-server>:3000
```

### Test Alertmanager

```bash
# Check status
curl http://localhost:9093/api/v1/status

# Send test alert
curl -X POST http://localhost:9093/api/v1/alerts -d '[{"labels":{"alertname":"TestAlert","severity":"info"},"annotations":{"summary":"Test alert"}}]'
```

## Prometheus Queries

### Useful PromQL Queries

**System Metrics:**
```promql
# CPU usage per node
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage per node
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk usage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

**HAProxy Metrics:**
```promql
# Backend status (1 = UP, 0 = DOWN)
haproxy_backend_up{backend="vless_pool"}

# Current connections per backend
haproxy_server_current_sessions{backend="vless_pool"}

# Request rate
rate(haproxy_frontend_http_requests_total[5m])
```

**WireGuard Metrics:**
```promql
# Tunnel bandwidth (bytes/sec)
rate(wireguard_received_bytes_total[5m])
rate(wireguard_sent_bytes_total[5m])

# Time since last handshake
time() - wireguard_latest_handshake_seconds
```

**NTOP Metrics:**
```promql
# Bandwidth per endpoint
rate(ntopng_bytes_total{server="oslo"}[5m])
rate(ntopng_bytes_total{server="amsterdam"}[5m])

# Top protocols
topk(5, ntopng_protocol_bytes_total)
```

## Grafana Dashboards

### Recommended Layout

**1. Infrastructure Overview**
- Total traffic (all nodes)
- Active connections (HAProxy)
- System resources (CPU, RAM)
- Alert status

**2. Per-Node Details**
- Oslo metrics
- Amsterdam metrics
- Germany LB metrics

**3. Network Analysis**
- WireGuard tunnel health
- Traffic patterns
- Geographic distribution

**4. Application Metrics**
- HAProxy performance
- NTOP statistics
- Container health

## Scripts

### `scripts/daily_report_tun_last.sh`

Daily tunnel statistics report sent to Telegram.

**Collected metrics:**
- Tunnel bandwidth usage (last 24h)
- Average latency
- Packet loss statistics
- Handshake status
- Traffic patterns

**Configuration:**
```bash
#!/bin/bash
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
PROMETHEUS_URL="http://localhost:9090"
```

**Manual run:**
```bash
/opt/scripts/daily_report_tun_last.sh
```

## Alert Configuration

### Alert Severity Levels

- **critical** - Immediate action required (sent to Telegram)
- **warning** - Attention needed (sent to Telegram)
- **info** - Informational (logged only)

### Example Custom Alert

```yaml
groups:
  - name: tunnel_alerts
    rules:
      - alert: WireGuardTunnelDown
        expr: time() - wireguard_latest_handshake_seconds > 600
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "WireGuard tunnel {{ $labels.interface }} is down"
          description: "No handshake in last 10 minutes on {{ $labels.instance }}"
```

## Maintenance

### Data Retention

**Prometheus:**
- Default: 15 days
- Adjust in `prometheus.yml`:
  ```yaml
  global:
    storage.tsdb.retention.time: 30d
  ```

**Grafana:**
- Dashboards stored in database
- Backup regularly:
  ```bash
  docker exec grafana grafana-cli admin export > grafana-backup.json
  ```

### Backup

```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/opt/backups/monitoring"
DATE=$(date +%Y%m%d)

# Stop containers
docker-compose stop

# Backup data
tar czf $BACKUP_DIR/prometheus-$DATE.tar.gz /opt/monitoring/prometheus-data
tar czf $BACKUP_DIR/grafana-$DATE.tar.gz /opt/monitoring/grafana-data

# Restart containers
docker-compose start
```

### Updates

```bash
# Update Docker images
docker-compose pull

# Restart with new images
docker-compose up -d

# Clean old images
docker image prune -a
```

## Troubleshooting

### Prometheus not scraping targets

```bash
# Check Prometheus logs
docker-compose logs prometheus

# Test target connectivity
curl http://<target-ip>:<port>/metrics

# Verify network from container
docker exec prometheus wget -O- <target-ip>:<port>/metrics

# Check firewall
ufw status
```

### Grafana not showing data

```bash
# Check Prometheus datasource
# Grafana → Configuration → Data Sources

# Test Prometheus connection
curl http://localhost:9090/api/v1/query?query=up

# Check Grafana logs
docker-compose logs grafana
```

### Alerts not firing

```bash
# Check alert rules syntax
promtool check rules configs/alert.rules.yml

# View active alerts in Prometheus
curl http://localhost:9090/api/v1/alerts

# Check Alertmanager
curl http://localhost:9093/api/v1/alerts
```

### High memory usage

```bash
# Check Prometheus memory
docker stats prometheus

# Reduce retention period
# Edit prometheus.yml
storage.tsdb.retention.time: 7d

# Restart
docker-compose restart prometheus
```

## Security

### Access Control

```bash
# Restrict Grafana access
# Use reverse proxy with authentication
# Or restrict by IP in firewall

ufw allow from <admin-ip> to any port 3000
ufw allow from 10.0.0.0/24 to any port 9090  # Prometheus (internal only)
```

### Credentials

- Store in `.env` file (not committed)
- Use Docker secrets for production
- Rotate Telegram bot token regularly

## Performance Optimization

### If monitoring server is slow:

**1. Reduce scrape frequency:**
```yaml
global:
  scrape_interval: 30s  # Increase from 10s
```

**2. Reduce retention:**
```yaml
storage.tsdb.retention.time: 7d  # Decrease from 15d
```

**3. Optimize queries:**
- Use recording rules for expensive queries
- Pre-aggregate common metrics

**4. Add more resources:**
- Increase RAM for Prometheus
- Add SSD for faster queries

## Related Documentation

- [Main README](../README.md)
- [Deployment Guide](../docs/DEPLOYMENT.md)
- [Security Guide](../docs/SECURITY.md)
- [All Endpoints](../)
