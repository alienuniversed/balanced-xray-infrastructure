# Netherlands Amsterdam Endpoint

VLESS endpoint with traffic analysis located in Amsterdam, Netherlands.

## Role

Secondary VLESS endpoint with comprehensive traffic monitoring and analysis.

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
- Local address: `10.0.0.2/24`
- Listen port: 51820
- Peer: Germany LB (`10.0.0.1`)

**Before use:**
1. Generate keys: `wg genkey | tee privatekey | wg pubkey > publickey`
2. Copy to `/etc/wireguard/wg0.conf`
3. Replace placeholders:
   - `<REDACTED_PRIVATE_KEY>` - your private key
   - `<GERMANY_LB_PUBLIC_KEY>` - Germany LB's public key
   - `<GERMANY_LB_PUBLIC_IP>` - Germany LB's public IP

### `configs/ntopng/ntopng.conf`
NTOP configuration for traffic analysis.

**Features:**
- Interface monitoring
- Flow collection
- Protocol analysis
- Bandwidth tracking
- Exporter for Prometheus

## Deployment

### 1. Install VLESS Server

```bash
# Install your VLESS implementation
# (e.g., Xray, V2Ray, or similar)

# Configure to listen on port 449
# Bind to WireGuard interface (10.0.0.2)
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

# Verify connectivity
ping 10.0.0.1  # Germany LB
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
# (requires NTOP API key from web interface)

# Start exporter
systemctl start ntopng-exporter
systemctl enable ntopng-exporter
```

### 6. Setup Daily Reports

```bash
# Copy reporting script
cp scripts/daily_dpi12.sh /opt/scripts/
chmod +x /opt/scripts/daily_dpi12.sh

# Configure Telegram credentials
nano /opt/scripts/daily_dpi12.sh

# Add to crontab
crontab -e
# Add: 0 9 * * * /opt/scripts/daily_dpi12.sh
```

## Verification

```bash
# Check WireGuard tunnel
wg show
ping 10.0.0.1  # Germany LB

# Check VLESS server
ss -tulpn | grep 449

# Check NTOP
curl http://localhost:3000  # Web interface
systemctl status ntopng

# Check exporters
curl http://localhost:8443/metrics  # Node Exporter
curl http://localhost:446/metrics   # NTOP Exporter

# Test from load balancer
# Germany LB should be able to connect to 10.0.0.2:449
```

## Network Configuration

### Firewall Rules

```bash
ufw allow 449/tcp from 10.0.0.0/24   # VLESS (from LB only)
ufw allow 51820/udp                   # WireGuard
ufw allow 8443/tcp from 10.0.0.0/24  # Node Exporter
ufw allow 446/tcp from 10.0.0.0/24   # NTOP Exporter
ufw allow 22/tcp                      # SSH
```

### IP Addressing

- **Public IP**: Your Amsterdam server public IP
- **WireGuard**: 10.0.0.2/24
- **VLESS Listen**: 10.0.0.2:449 (via WireGuard)

## Load Balancing Weight

This endpoint has a weight of **245** in HAProxy configuration (vs Oslo's 255).

**Why lower weight?**
- Adjust based on server capacity
- Can be used for traffic shaping
- Useful for gradual traffic migration

To adjust weight, edit `germany-loadbalancer/configs/haproxy.cfg`:
```haproxy
server ams-node 10.0.0.2:449 check weight 245  # Increase/decrease as needed
```

## NTOP Traffic Analysis

### Accessing NTOP Web Interface

**Secure access via SSH tunnel:**

```bash
# From your local machine
ssh -L 3000:localhost:3000 user@amsterdam-server

# Then access: http://localhost:3000
```

### Comparing with Oslo

Both Amsterdam and Oslo endpoints run NTOP, allowing:
- Traffic comparison between regions
- Protocol distribution analysis
- Geographic traffic patterns
- Performance benchmarking

View both in Grafana dashboards with labels:
- `server: amsterdam`
- `server: oslo`

## Scripts

### `scripts/daily_dpi12.sh`

Daily traffic analysis report script (same as Oslo).

**Configuration:**
```bash
# Edit to set Amsterdam-specific values:
NTOP_API_KEY="amsterdam_api_key"
NTOP_HOST="http://localhost:3000"
SERVER_NAME="Amsterdam"
```

## Troubleshooting

### WireGuard tunnel down

```bash
# Check status
systemctl status wg-quick@wg0

# View logs
journalctl -u wg-quick@wg0 -f

# Check handshake
wg show wg0 latest-handshakes

# Restart
wg-quick down wg0
wg-quick up wg0

# Test connectivity
ping 10.0.0.1  # Germany LB
```

### Backend shows DOWN in HAProxy

```bash
# From Amsterdam, test VLESS is listening
ss -tulpn | grep 449

# From Germany LB, test connectivity
ping 10.0.0.2
telnet 10.0.0.2 449

# Check HAProxy logs on Germany LB
tail -f /var/log/haproxy.log | grep ams-node
```

### NTOP not collecting data

```bash
# Check interface
ip link show

# Verify NTOP is capturing
tcpdump -i eth0 -c 10

# Check NTOP status
systemctl status ntopng

# Review logs
journalctl -u ntopng -n 50
```

### High latency

```bash
# Measure ping to Germany LB
ping -c 100 10.0.0.1

# Check for packet loss
mtr 10.0.0.1

# Monitor network stats
sar -n DEV 1 10

# Check for congestion
tc -s qdisc show dev wg0
```

## Geographic Routing Considerations

Amsterdam is strategically located for:
- EU traffic
- Low latency to Western Europe
- Good connectivity to UK

**Latency expectations:**
- To Germany LB: <10ms
- To UK: <20ms
- To France: <15ms
- To Spain: <30ms

## Monitoring Integration

This endpoint is monitored by SPB monitoring server via:
- **Prometheus** scraping on port 8443 (Node Exporter)
- **NTOP Exporter** on port 446
- **Grafana** dashboards with `location: netherlands` label

**Key metrics tracked:**
- System resources (CPU, RAM, network)
- WireGuard tunnel health and bandwidth
- NTOP traffic statistics
- VLESS connection counts
- Geographic distribution of traffic

## Maintenance

### Regular Tasks

**Daily:**
- Review NTOP traffic reports
- Compare bandwidth with Oslo endpoint
- Check for unusual traffic patterns

**Weekly:**
- Review system logs
- Check disk usage (NTOP flow storage)
- Verify backup status
- Compare performance with Oslo

**Monthly:**
- Rotate WireGuard keys
- Review and optimize firewall rules
- Update software packages
- Capacity planning based on trends

### Backup and Recovery

```bash
# Backup NTOP configuration
tar czf ntopng-backup-$(date +%Y%m%d).tar.gz /etc/ntopng/

# Backup WireGuard config
cp /etc/wireguard/wg0.conf /root/backups/

# Backup VLESS config
# (depends on your implementation)
```

## Performance Optimization

### If experiencing high load:

**1. Check connection count:**
```bash
ss -ant | grep 449 | wc -l
```

**2. Optimize NTOP:**
```bash
# Reduce flow retention in ntopng.conf
--max-num-flows=100000
--max-num-hosts=50000
```

**3. Adjust HAProxy weight:**
- Decrease weight if overloaded
- Contact admin to adjust Germany LB config

**4. Monitor resource usage:**
```bash
htop
iotop
nethogs
```

## Scaling Considerations

If this endpoint needs scaling:

**Vertical scaling:**
- Add more CPU cores
- Increase RAM
- Upgrade network interface

**Horizontal scaling:**
- Add another Amsterdam node
- Update HAProxy with new backend
- Distribute traffic across multiple nodes

## Related Documentation

- [Main README](../README.md)
- [Deployment Guide](../docs/DEPLOYMENT.md)
- [Security Guide](../docs/SECURITY.md)
- [Germany Load Balancer](../germany-loadbalancer/README.md)
- [Norway Oslo Endpoint](../norway-oslo/README.md)
