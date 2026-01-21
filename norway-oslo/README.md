# Norway Oslo Endpoint

VLESS endpoint with traffic analysis located in Oslo, Norway.

## Role

Primary VLESS endpoint with comprehensive traffic monitoring and analysis.

## Services

- **VLESS Server** - Proxy endpoint (port 449)
- **NTOP (ntopng)** - Deep packet inspection and traffic analysis
- **Node Exporter** - System metrics (port 8443)
- **NTOP Exporter** - Traffic metrics (port 446)
- **WireGuard** - VPN tunnel to Germany load balancer

## Configuration Files

### `configs/wg0.conf.example`
WireGuard tunnel to Germany load balancer.

**Network configuration:**
- Local address: `10.0.0.5/32`
- Peer: Germany LB (`10.0.3.1`)
- Port: 51823 (custom port, not default 51820)

**Before use:**
1. Generate keys: `wg genkey | tee privatekey | wg pubkey > publickey`
2. Copy to `/etc/wireguard/wg0.conf`
3. Replace placeholders:
   - `<REDACTED_PRIVATE_KEY>` - your private key
   - `<GERMANY_LB_PUBLIC_KEY>` - Germany LB's public key
   - `<GERMANY_LB_PUBLIC_IP>` - Germany LB's public IP

### `configs/ntopng/ntopng.conf`
NTOP configuration for traffic analysis.

**Key features:**
- Interface monitoring
- Flow collection
- Protocol analysis
- Bandwidth tracking
- Exporter for Prometheus integration

## Deployment

### 1. Install VLESS Server

```bash
# Install your VLESS implementation
# (e.g., Xray, V2Ray, or similar)

# Configure to listen on port 449
# Bind to WireGuard interface (10.0.0.5)
```

### 2. Configure WireGuard

```bash
# Install WireGuard
apt install -y wireguard

# Copy and configure
cp configs/wg0.conf.example /etc/wireguard/wg0.conf
nano /etc/wireguard/wg0.conf

# Start tunnel
wg-quick up wg0
systemctl enable wg-quick@wg0

# Verify
ping 10.0.3.1  # Germany LB
```

### 3. Deploy NTOP

```bash
# Install ntopng
apt install -y ntopng

# Copy configuration
cp configs/ntopng/ntopng.conf /etc/ntopng/

# Edit interface name
nano /etc/ntopng/ntopng.conf
# Change -i=eth0 to your actual interface

# Start ntopng
systemctl start ntopng
systemctl enable ntopng
```

### 4. Deploy Node Exporter

```bash
# Copy service file
cp services/node_exporter.service /etc/systemd/system/

# Install node_exporter binary
# (see main DEPLOYMENT.md)

# Start service
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
```

### 5. Deploy NTOP Exporter

```bash
# Copy service file
cp services/ntopng-exporter.service /etc/systemd/system/

# Configure NTOP API access
# (requires NTOP API key)

# Start exporter
systemctl start ntopng-exporter
systemctl enable ntopng-exporter
```

### 6. Setup Daily Reports

```bash
# Copy reporting script
cp scripts/daily_dpi12.sh /opt/scripts/
chmod +x /opt/scripts/daily_dpi12.sh

# Configure Telegram credentials in script
nano /opt/scripts/daily_dpi12.sh

# Add to crontab for daily execution
crontab -e
# Add: 0 9 * * * /opt/scripts/daily_dpi12.sh
```

## Verification

```bash
# Check WireGuard
wg show
ping 10.0.3.1  # Germany LB

# Check VLESS server
ss -tulpn | grep 449

# Check NTOP
curl http://localhost:3000  # Web interface
systemctl status ntopng

# Check exporters
curl http://localhost:8443/metrics  # Node Exporter
curl http://localhost:446/metrics   # NTOP Exporter

# Test from load balancer
# Germany LB should be able to connect to 10.0.0.5:449
```

## Network Configuration

### Firewall Rules

```bash
ufw allow 449/tcp from 10.0.0.0/24   # VLESS (from LB only)
ufw allow 51823/udp                   # WireGuard
ufw allow 8443/tcp from 10.0.0.0/24  # Node Exporter
ufw allow 446/tcp from 10.0.0.0/24   # NTOP Exporter
ufw allow 22/tcp                      # SSH (consider IP restriction)
```

### IP Addressing

- **Public IP**: Your Oslo server public IP
- **WireGuard**: 10.0.0.5/32
- **VLESS Listen**: 10.0.0.5:449 (via WireGuard)

## NTOP Traffic Analysis

### Accessing NTOP Web Interface

**Secure access via SSH tunnel:**

```bash
# From your local machine
ssh -L 3000:localhost:3000 user@oslo-server

# Then access: http://localhost:3000
```

### Key Metrics

NTOP provides:
- Real-time bandwidth usage
- Protocol distribution (HTTP, HTTPS, DNS, etc.)
- Top talkers (IPs with most traffic)
- Flow analysis
- Geolocation of connections
- DPI (Deep Packet Inspection) results

### Exporting to Prometheus

NTOP metrics are exported on port 446 and include:
- Total bandwidth (in/out)
- Packet counts
- Active flows
- Top protocols usage

## Scripts

### `scripts/daily_dpi12.sh`

Daily traffic analysis report script.

**Features:**
- Collects NTOP statistics via API
- Analyzes bandwidth usage
- Identifies top protocols
- Sends daily report to Telegram

**Configuration:**
```bash
# Edit script to set:
NTOP_API_KEY="your_api_key"
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

**Manual execution:**
```bash
/opt/scripts/daily_dpi12.sh
```

## Troubleshooting

### WireGuard tunnel down

```bash
# Check logs
journalctl -u wg-quick@wg0 -f

# Check handshake
wg show wg0 latest-handshakes

# Restart tunnel
wg-quick down wg0
wg-quick up wg0

# Verify connectivity
ping 10.0.3.1
```

### VLESS not responding

```bash
# Check if service is running
ss -tulpn | grep 449

# Check logs (depends on your VLESS implementation)
journalctl -u vless -f

# Test locally
curl -v http://10.0.0.5:449
```

### NTOP issues

```bash
# Check status
systemctl status ntopng

# Check logs
journalctl -u ntopng -f

# Verify interface
ip link show

# Check permissions
ls -l /var/lib/ntopng
```

### High CPU usage

```bash
# Check NTOP resource usage
top -p $(pgrep ntopng)

# Check VLESS connections
ss -ant | grep 449 | wc -l

# Monitor system
htop
```

## Monitoring Integration

This endpoint is monitored by:
- **Prometheus** (SPB monitoring server)
- **Grafana** dashboards showing:
  - System resources (CPU, RAM, disk)
  - Network traffic (WireGuard tunnel)
  - NTOP statistics
  - VLESS connection counts

## Maintenance

### Regular tasks

**Daily:**
- Review NTOP traffic reports
- Check for anomalies in bandwidth usage

**Weekly:**
- Review system logs
- Check disk usage (NTOP stores flows)
- Verify backup status

**Monthly:**
- Rotate WireGuard keys (optional)
- Review firewall rules
- Update software packages

### Cleanup

```bash
# Clean old NTOP data (if disk space low)
rm -rf /var/lib/ntopng/flows/*

# Restart NTOP
systemctl restart ntopng
```

## Related Documentation

- [Main README](../README.md)
- [Deployment Guide](../docs/DEPLOYMENT.md)
- [Security Guide](../docs/SECURITY.md)
- [Germany Load Balancer](../germany-loadbalancer/README.md)
