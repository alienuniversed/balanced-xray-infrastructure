# SPB AI Video Server

AI-powered CCTV video analysis server located in Saint Petersburg.

## Role

Dedicated server for AI-based video processing and CCTV surveillance management. This is a separate infrastructure component from the main proxy system but shares monitoring integration.

## Services

- **AI Video Processing** - Computer vision and object detection
- **CCTV Management** - Video stream aggregation and storage
- **Node Exporter** - System metrics (port 9100)
- **cAdvisor** - Container metrics (port 8080)

## Why Separate Infrastructure?

This server is isolated from the proxy infrastructure for several reasons:

1. **Resource Isolation** - AI video processing is CPU/GPU intensive
2. **Security** - CCTV data should be segregated
3. **Local Processing** - Low latency for on-premise cameras
4. **Independent Scaling** - Can scale video processing separately

## Architecture

```
┌─────────────────────────────────────────┐
│     SPB AI Video Server (Proxmox VM)    │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   AI Video Processing Pipeline    │ │
│  │                                   │ │
│  │  ┌──────────┐  ┌──────────────┐ │ │
│  │  │  Video   │  │  Object      │ │ │
│  │  │  Ingest  │→ │  Detection   │ │ │
│  │  └──────────┘  └──────┬───────┘ │ │
│  │                       │          │ │
│  │  ┌──────────┐  ┌─────▼────────┐ │ │
│  │  │  Alert   │← │  Classification│ │
│  │  │  System  │  │  & Analysis  │ │ │
│  │  └──────────┘  └──────────────┘ │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────┐  ┌────────────────┐ │
│  │ Node Exporter │  │   cAdvisor     │ │
│  │    :9100      │  │     :8080      │ │
│  └───────┬───────┘  └────────┬───────┘ │
│          │                    │         │
└──────────┼────────────────────┼─────────┘
           │                    │
           └────────┬───────────┘
                    │
           ┌────────▼─────────┐
           │  SPB Monitoring  │
           │  Prometheus      │
           └──────────────────┘
```

## Configuration Files

### `configs/cadvisor-docker-compose.yml`

Docker Compose configuration for cAdvisor container monitoring.

**Purpose:**
- Monitor Docker containers running AI workloads
- Track resource usage (CPU, GPU, memory)
- Export metrics to Prometheus

**Configuration:**
```yaml
version: '3'
services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped
```

### `services/node_exporter.service`

Systemd service for Node Exporter.

**Monitors:**
- System CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Temperature (if GPU present)

## Deployment

### 1. Proxmox VM Setup

```bash
# Create VM in Proxmox
# Recommended specs:
# - CPU: 4+ cores (8+ for heavy AI workloads)
# - RAM: 16GB+ (32GB+ recommended)
# - GPU: NVIDIA GPU (optional but recommended)
# - Disk: 500GB+ SSD (for video storage)
# - Network: 1Gbps+

# If using GPU, enable PCI passthrough in Proxmox
```

### 2. Install Docker

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install NVIDIA Docker (if using GPU)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt update
apt install -y nvidia-docker2
systemctl restart docker
```

### 3. Deploy cAdvisor

```bash
# Copy config
cp configs/cadvisor-docker-compose.yml /opt/cadvisor/docker-compose.yml

# Start cAdvisor
cd /opt/cadvisor
docker-compose up -d

# Verify
curl http://localhost:8080/metrics
```

### 4. Deploy Node Exporter

```bash
# Copy service file
cp services/node_exporter.service /etc/systemd/system/

# Download node_exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

# Create user
useradd -rs /bin/false node_exporter

# Start service
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
```

### 5. Deploy AI Video Processing

```bash
# This is custom implementation-specific
# Example structure:

# Deploy your AI video processing stack
# Options:
# - Frigate NVR (https://frigate.video/)
# - Shinobi (https://shinobi.video/)
# - Custom TensorFlow/PyTorch pipeline
# - ZoneMinder with AI plugins
```

## Verification

```bash
# Check Node Exporter
curl http://localhost:9100/metrics

# Check cAdvisor
curl http://localhost:8080/metrics
docker ps | grep cadvisor

# Check video processing (implementation-specific)
# E.g., check logs, test camera feeds, verify recordings
```

## Network Configuration

### Firewall Rules

```bash
# Only allow from monitoring server
ufw allow from 10.0.0.0/24 to any port 9100  # Node Exporter
ufw allow from 10.0.0.0/24 to any port 8080  # cAdvisor

# Allow camera feeds (if cameras on separate network)
ufw allow from 192.168.1.0/24 to any port 554  # RTSP

# SSH access
ufw allow 22/tcp

ufw enable
```

### IP Addressing

- **Proxmox Host**: Internal SPB network
- **VM IP**: Static IP in SPB network
- **Cameras**: Typically 192.168.x.x (separate VLAN recommended)

## Monitoring Integration

### Prometheus Scrape Config

In SPB monitoring server's `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'pve-spb-cctv-aivm'
    static_configs:
      - targets: ['<VM_IP>:9100']  # Node Exporter
        labels:
          instance: 'spb-ai-videoserver'
          role: 'video-processing'
  
  - job_name: 'cadvisor-ai-videoserver'
    static_configs:
      - targets: ['<VM_IP>:8080']  # cAdvisor
        labels:
          instance: 'spb-ai-videoserver'
```

### Key Metrics to Monitor

**System Resources:**
- CPU usage (AI processing is CPU-intensive)
- GPU utilization (if applicable)
- Memory usage (video buffers)
- Disk I/O (video storage)
- Network bandwidth (camera streams)

**Application Specific:**
- Frames processed per second (FPS)
- Detection latency
- Alert generation rate
- Storage usage growth rate
- Camera connection status

## AI Workload Considerations

### GPU Acceleration

If using NVIDIA GPU:

```bash
# Verify GPU is accessible
nvidia-smi

# Run container with GPU access
docker run --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### Performance Optimization

**1. Reduce frame rate:**
```yaml
# Process every 2nd frame instead of every frame
frame_skip: 2
```

**2. Adjust detection regions:**
```yaml
# Only process areas of interest
zones:
  - name: entrance
    coordinates: [0,0,1920,200]
```

**3. Use lightweight models:**
- YOLOv5-tiny instead of YOLOv5
- MobileNet instead of ResNet

**4. Optimize storage:**
```bash
# Use hardware-accelerated encoding
ffmpeg -hwaccel cuda -i input.mp4 -c:v h264_nvenc output.mp4
```

## Storage Management

### Video Retention

```bash
# Automatic cleanup script
#!/bin/bash
# Keep last 30 days of recordings
find /video/storage -type f -mtime +30 -delete

# Add to crontab
# 0 2 * * * /opt/scripts/cleanup_videos.sh
```

### Storage Monitoring

```bash
# Alert on low disk space
# In prometheus alert.rules.yml:
- alert: VideoStorageLow
  expr: node_filesystem_avail_bytes{mountpoint="/video/storage"} / node_filesystem_size_bytes < 0.1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Video storage is running low on {{ $labels.instance }}"
```

## Troubleshooting

### High CPU usage

```bash
# Check which process is using CPU
htop

# Check AI processing load
docker stats

# If overloaded:
# - Reduce camera count
# - Reduce frame rate
# - Reduce detection zones
# - Increase detection interval
```

### Video stream issues

```bash
# Test camera connectivity
ffprobe rtsp://camera-ip:554/stream

# Check network bandwidth
iftop

# Monitor packet loss
ping -c 100 camera-ip

# Check for buffer issues
dmesg | grep -i memory
```

### GPU not detected

```bash
# Check GPU visibility
nvidia-smi

# Verify Docker can access GPU
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Check NVIDIA Docker runtime
cat /etc/docker/daemon.json
# Should contain: "default-runtime": "nvidia"
```

### Disk filling up

```bash
# Check storage usage
df -h
du -sh /video/storage/*

# Check oldest recordings
find /video/storage -type f -printf '%T+ %p\n' | sort | head -20

# Enable automatic cleanup
# See Storage Management section above
```

## Security Considerations

### Camera Network Isolation

```bash
# Put cameras on separate VLAN
# Firewall rules to prevent cameras accessing internet
# Only allow connection to video server

# Example iptables rules:
iptables -A FORWARD -i cameras_vlan -o wan -j DROP
iptables -A FORWARD -i cameras_vlan -d <video_server_ip> -j ACCEPT
```

### Access Control

```bash
# Restrict SSH access
# Use key-based authentication only
# No password authentication

# Restrict web interface access
# Use VPN or SSH tunnel
# Or use reverse proxy with authentication
```

### Data Privacy

- Encrypt video storage at rest
- Use HTTPS for web interface
- Implement access logging
- Regular security audits
- Comply with local CCTV regulations

## Maintenance

### Regular Tasks

**Daily:**
- Check camera connectivity
- Review AI detection accuracy
- Monitor storage growth

**Weekly:**
- Review system logs
- Check for failed recordings
- Verify backup integrity

**Monthly:**
- Update AI models (if applicable)
- Review retention policies
- Performance optimization
- Security patches

### Backup Strategy

```bash
# Backup configuration
tar czf config-backup-$(date +%Y%m%d).tar.gz /etc/video-system/

# Backup important recordings
rsync -av --delete /video/storage/important/ /backup/video-archive/

# Database backup (if using database)
mysqldump video_db > video_db_backup.sql
```

## Capacity Planning

### Current Capacity

Calculate storage needs:
```
Storage per camera = bitrate (Mbps) × 3600 (sec/hour) × 24 (hours) × retention (days) / 8 (bits/byte) / 1024 (MB/GB)

Example: 4 Mbps × 3600 × 24 × 30 / 8 / 1024 = ~1.2 TB per camera per month
```

### Scaling

**Vertical scaling (single server):**
- Add more CPU cores
- Add more RAM
- Add more storage
- Add GPU(s)

**Horizontal scaling (multiple servers):**
- Distribute cameras across multiple servers
- Use load balancer for web interface
- Shared storage for recordings
- Centralized monitoring

## Related Documentation

- [Main README](../README.md)
- [SPB Monitoring](../spb-monitoring/README.md)
- [Security Guide](../docs/SECURITY.md)

## External Resources

- [Frigate NVR Documentation](https://docs.frigate.video/)
- [NVIDIA Docker](https://github.com/NVIDIA/nvidia-docker)
- [TensorFlow Object Detection](https://github.com/tensorflow/models/tree/master/research/object_detection)
