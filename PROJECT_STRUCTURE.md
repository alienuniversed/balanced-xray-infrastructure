# Project Structure

Complete directory structure and file organization for the load-balanced HAProxy infrastructure.

## Directory Tree

```
load-balanced-haproxy-infrastructure/
├── README.md                       # Main project documentation
├── LICENSE                         # MIT License
├── CONTRIBUTING.md                 # Contribution guidelines
├── .gitignore                      # Git ignore rules
├── .env.example                    # Environment variables template
│
├── docs/                           # Documentation
│   ├── DEPLOYMENT.md               # Deployment guide
│   ├── SECURITY.md                 # Security best practices
│   └── diagrams/                   # Infrastructure diagrams
│       ├── Cloud_Infrastructure.png
│       ├── Infrastructure_Monitoring.png
│       ├── Network_Schema.png
│       └── Virtualization_Schema_drawio.png
│
├── germany-loadbalancer/           # Germany Load Balancer (Frankfurt)
│   ├── README.md                   # Component-specific documentation
│   ├── configs/                    # Configuration files
│   │   ├── haproxy.cfg.example     # HAProxy load balancer config
│   │   ├── wg0.conf.example        # WireGuard tunnel to Amsterdam
│   │   ├── wg3.conf.example        # WireGuard tunnel to Oslo
│   │   └── cadvisor-docker-compose.yml  # Container monitoring
│   └── services/                   # Systemd service files
│       └── node_exporter.service
│
├── norway-oslo/                    # Oslo Endpoint (Norway)
│   ├── README.md                   # Component-specific documentation
│   ├── configs/                    # Configuration files
│   │   ├── wg0.conf.example        # WireGuard tunnel to Germany
│   │   └── ntopng/                 # NTOP traffic analyzer
│   │       ├── ntopng.conf
│   │       ├── ntopng.conf.nprobe.sample
│   │       └── ntopng.conf.d/
│   ├── scripts/                    # Automation scripts
│   │   └── daily_dpi12.sh          # Daily traffic report
│   └── services/                   # Systemd service files
│       ├── node_exporter.service
│       ├── ntopng.service
│       ├── ntopng@.service
│       └── ntopng-exporter.service
│
├── netherlands-amsterdam/          # Amsterdam Endpoint (Netherlands)
│   ├── README.md                   # Component-specific documentation
│   ├── configs/                    # Configuration files
│   │   ├── wg0.conf.example        # WireGuard tunnel to Germany
│   │   └── ntopng/                 # NTOP traffic analyzer
│   │       ├── ntopng.conf
│   │       └── ntopng.conf.d/
│   ├── scripts/                    # Automation scripts
│   │   └── daily_dpi12.sh          # Daily traffic report
│   └── services/                   # Systemd service files
│       ├── node_exporter.service
│       ├── ntop-service.service
│       ├── ntopng.service
│       ├── ntopng@.service
│       └── ntopng-exporter.service
│
├── spb-monitoring/                 # SPB Monitoring Server (Saint Petersburg)
│   ├── README.md                   # Component-specific documentation
│   ├── configs/                    # Configuration files
│   │   ├── prometheus.yml.example  # Prometheus scrape config
│   │   ├── alertmanager.yml        # Alert routing config
│   │   ├── alert.rules.yml         # Alert rules
│   │   ├── docker-compose.yml      # Monitoring stack compose
│   │   └── monitoring-docker-compose.yml  # Alternative compose
│   └── scripts/                    # Automation scripts
│       ├── daily_report_tun_last.sh  # Tunnel statistics report
│       └── [other metric collectors]
│
└── spb-ai-videoserver/             # SPB AI Video Server
    ├── README.md                   # Component-specific documentation
    ├── configs/                    # Configuration files
    │   └── cadvisor-docker-compose.yml  # Container monitoring
    └── services/                   # Systemd service files
        └── node_exporter.service
```

## File Types

### Configuration Files

**HAProxy** (`*.cfg`)
- Load balancer configuration
- Backend definitions
- Health checks
- Sticky sessions

**WireGuard** (`*.conf`)
- VPN tunnel configuration
- Peer definitions
- Encryption keys (template only)

**Prometheus** (`prometheus.yml`)
- Scrape targets
- Scrape intervals
- Alert rules

**Alertmanager** (`alertmanager.yml`)
- Alert routing
- Notification channels
- Grouping rules

**NTOP** (`ntopng.conf`)
- Traffic analysis
- Interface monitoring
- Flow collection

**Docker Compose** (`docker-compose.yml`)
- Service definitions
- Volume mappings
- Network configuration

### Service Files

**Systemd Units** (`*.service`)
- Service definitions
- Auto-start configuration
- Dependencies

### Scripts

**Bash Scripts** (`*.sh`)
- Automation
- Metric collection
- Reporting

## Configuration Templates

All sensitive configuration files use `.example` suffix:

```
haproxy.cfg.example     → Copy to haproxy.cfg
wg0.conf.example        → Copy to wg0.conf
prometheus.yml.example  → Copy to prometheus.yml
.env.example           → Copy to .env
```

**Never commit actual configuration files to git!**

## File Naming Conventions

### Configuration Files
- Use `.example` suffix for templates
- Use descriptive names: `haproxy.cfg` not `config.cfg`
- Group related configs in subdirectories

### Scripts
- Use snake_case: `daily_report.sh`
- Include descriptive names: `collect_metrics.sh`
- Add shebang and headers

### Service Files
- Follow systemd naming: `service_name.service`
- Include descriptive Unit descriptions

## Component Breakdown

### Germany Load Balancer
**Purpose**: Primary load balancer and traffic distributor  
**Key Files**: 
- `haproxy.cfg.example` - Main load balancing config
- `wg0.conf.example` / `wg3.conf.example` - VPN tunnels

### Norway Oslo Endpoint
**Purpose**: Primary VLESS endpoint with traffic analysis  
**Key Files**:
- `wg0.conf.example` - VPN tunnel to Germany
- `ntopng.conf` - Traffic analyzer config
- `daily_dpi12.sh` - Traffic reporting script

### Netherlands Amsterdam Endpoint
**Purpose**: Secondary VLESS endpoint with traffic analysis  
**Key Files**:
- `wg0.conf.example` - VPN tunnel to Germany
- `ntopng.conf` - Traffic analyzer config
- `daily_dpi12.sh` - Traffic reporting script

### SPB Monitoring
**Purpose**: Centralized monitoring and alerting  
**Key Files**:
- `prometheus.yml.example` - Metrics collection
- `alertmanager.yml` - Alert routing
- `alert.rules.yml` - Alert definitions
- `daily_report_tun_last.sh` - Tunnel statistics

### SPB AI Video Server
**Purpose**: AI-powered CCTV video analysis  
**Key Files**:
- `cadvisor-docker-compose.yml` - Container monitoring
- `node_exporter.service` - System metrics

## Documentation Structure

### Main Documentation
- `README.md` - Overview, quick start, features
- `CONTRIBUTING.md` - Contribution guidelines
- `LICENSE` - MIT License

### Technical Documentation
- `docs/DEPLOYMENT.md` - Step-by-step deployment
- `docs/SECURITY.md` - Security best practices
- `docs/diagrams/` - Visual architecture

### Component Documentation
- `<component>/README.md` - Specific to each component
- Deployment steps
- Verification procedures
- Troubleshooting guides

## Data Flow

```
User Request
    ↓
Germany Load Balancer (HAProxy)
    ↓ (via WireGuard)
Oslo/Amsterdam Endpoints (VLESS)
    ↓
Internet
    ↓
Metrics Collection (Node Exporter, cAdvisor, NTOP)
    ↓
SPB Monitoring (Prometheus)
    ↓
Visualization (Grafana)
    ↓
Alerts (Alertmanager → Telegram)
```

## Network Topology

```
Public Internet
    │
    ├─ Germany LB (Public IP: <GERMANY_IP>)
    │   └─ WireGuard VPN (10.0.0.1)
    │       ├─ wg0 ──→ Amsterdam (10.0.0.2)
    │       └─ wg3 ──→ Oslo (10.0.0.5)
    │
    ├─ Amsterdam Endpoint (Public IP: <AMSTERDAM_IP>)
    │   └─ WireGuard VPN (10.0.0.2)
    │
    └─ Oslo Endpoint (Public IP: <OSLO_IP>)
        └─ WireGuard VPN (10.0.0.5)

Private Network (SPB)
    │
    ├─ Monitoring Server
    │   └─ Prometheus scrapes all nodes via VPN
    │
    └─ AI Video Server (Proxmox VM)
        └─ Monitored by Prometheus
```

## Port Matrix

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| HAProxy Frontend | 443 | TCP | Public |
| HAProxy Stats | 447 | TCP | Restricted |
| HAProxy Prometheus | 448 | TCP | Internal |
| VLESS Backend | 449 | TCP | Internal (VPN) |
| WireGuard wg0 | 51820 | UDP | Public |
| WireGuard wg3 | 51823 | UDP | Public |
| Prometheus | 9090 | TCP | Internal |
| Grafana | 3000 | TCP | Internal |
| Alertmanager | 9093 | TCP | Internal |
| Node Exporter | 8443/9100 | TCP | Internal |
| cAdvisor | 8080/8446 | TCP | Internal |
| NTOP Web | 3000 | TCP | Local only |
| NTOP Exporter | 446 | TCP | Internal |

## Environment Variables

See `.env.example` for complete list:

- `GERMANY_PRIVATE_KEY` - WireGuard private key
- `OSLO_PUBLIC_IP` - Oslo endpoint public IP
- `AMSTERDAM_PUBLIC_IP` - Amsterdam endpoint public IP
- `HAPROXY_STATS_PASSWORD` - HAProxy stats authentication
- `TELEGRAM_BOT_TOKEN` - Bot token for alerts
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password

## Best Practices

### Configuration Management
1. Always use `.example` files as templates
2. Never commit sensitive data
3. Document all changes
4. Version control all configs

### File Organization
1. Group related files in directories
2. Use descriptive names
3. Include README in each component
4. Keep documentation up-to-date

### Security
1. Restrict file permissions (600 for keys)
2. Use environment variables for secrets
3. Regular security audits
4. Follow principle of least privilege

---

**This structure represents a production-ready, geo-distributed infrastructure with comprehensive monitoring and documentation.**
