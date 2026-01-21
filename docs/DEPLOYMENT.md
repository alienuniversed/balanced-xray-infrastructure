# Руководство по развёртыванию

Пошаговое руководство по развёртыванию балансируемой HAProxy инфраструктуры.

> 🤖 **Автоматизация**: Для автоматизированного развёртывания рекомендуется использовать [**cosmic-ops**](https://github.com/alienuniversed/cosmic-ops) с Ansible playbooks. Это руководство описывает **ручное** развёртывание для понимания архитектуры.

## Два способа развёртывания

### 1️⃣ Автоматизированное (Рекомендуется)

Используйте [cosmic-ops](https://github.com/alienuniversed/cosmic-ops) с 87 Ansible playbooks:

```bash
# Клонируйте cosmic-ops
git clone https://github.com/alienuniversed/cosmic-ops
cd cosmic-ops

# Настройте inventory
cp inventory.example.yml inventory.yml
nano inventory.yml

# Запустите полное развёртывание
ansible-playbook -i inventory.yml playbooks/deploy-all.yml

# Или развёртывание по компонентам
ansible-playbook -i inventory.yml playbooks/haproxy/deploy.yml
ansible-playbook -i inventory.yml playbooks/wireguard/deploy.yml
ansible-playbook -i inventory.yml playbooks/monitoring/deploy.yml
```

**Преимущества Ansible подхода**:
- ✅ Автоматизация всего процесса
- ✅ Идемпотентность (можно запускать многократно)
- ✅ Управление конфигурацией из единого места
- ✅ Откат изменений при ошибках
- ✅ ChatOps интеграция через Telegram bot

### 2️⃣ Ручное (Описано ниже)

Подходит для:
- Понимания архитектуры
- Обучения
- Кастомизации под специфические нужды
- Troubleshooting

---

## Перед началом

### Что потребуется

- 3x VPS/выделенные серверы (Oslo, Amsterdam, Germany)
- 1x On-premise сервер для мониторинга (SPB)
- Публичные IPv4 адреса для всех endpoint'ов
- Root/sudo доступ ко всем серверам

### Версии ПО

- Ubuntu 22.04 LTS
- Docker 24.0+
- HAProxy 2.8+
- WireGuard
- Python 3.10+

---

## Этап 1: Подготовка серверов

### 1.1 Обновление всех серверов

```bash
# На каждом сервере (Oslo, Amsterdam, Germany, SPB)
apt update && apt upgrade -y
apt install -y curl wget git vim htop net-tools

# Перезагрузка если обновлялось ядро
reboot
```

### 1.2 Установка Docker

```bash
# На всех серверах
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

usermod -aG docker $USER
newgrp docker

# Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Проверка
docker --version
docker-compose --version
```

### 1.3 Установка WireGuard

```bash
# На Oslo, Amsterdam, Germany
apt install -y wireguard wireguard-tools

# Проверка
modprobe wireguard
lsmod | grep wireguard
```

### 1.4 Установка HAProxy

```bash
# Только на Germany load balancer
apt install -y haproxy

# Проверка версии (должна быть 2.4+)
haproxy -v
```

---

## Этап 2: Настройка WireGuard

### 2.1 Генерация ключей

```bash
# На каждом сервере
cd /etc/wireguard
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

# Просмотр ключей
cat privatekey  # ДЕРЖИТЕ В СЕКРЕТЕ!
cat publickey   # Передайте другим узлам
```

### 2.2 Настройка - Germany Load Balancer

```bash
# Germany: wg0.conf (к Amsterdam)
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <GERMANY_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <AMSTERDAM_PUBLIC_KEY>
AllowedIPs = 10.0.0.2/32
Endpoint = <AMSTERDAM_PUBLIC_IP>:51820
PersistentKeepalive = 25
EOF

# Germany: wg3.conf (к Oslo)
cat > /etc/wireguard/wg3.conf << EOF
[Interface]
PrivateKey = <GERMANY_PRIVATE_KEY>
Address = 10.0.3.1/24
ListenPort = 51823

[Peer]
PublicKey = <OSLO_PUBLIC_KEY>
AllowedIPs = 10.0.0.5/32
Endpoint = <OSLO_PUBLIC_IP>:51823
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/*.conf
```

### 2.3 Настройка - Oslo Endpoint

```bash
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <OSLO_PRIVATE_KEY>
Address = 10.0.0.5/32

[Peer]
PublicKey = <GERMANY_PUBLIC_KEY>
Endpoint = <GERMANY_PUBLIC_IP>:51823
AllowedIPs = 10.0.3.1/32
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/wg0.conf
```

### 2.4 Настройка - Amsterdam Endpoint

```bash
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <AMSTERDAM_PRIVATE_KEY>
Address = 10.0.0.2/24
ListenPort = 51820

[Peer]
PublicKey = <GERMANY_PUBLIC_KEY>
AllowedIPs = 10.0.0.1/32
Endpoint = <GERMANY_PUBLIC_IP>:51820
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/wg0.conf
```

### 2.5 Запуск туннелей

```bash
# На всех узлах с WireGuard
wg-quick up wg0
systemctl enable wg-quick@wg0

# На Germany (также wg3)
wg-quick up wg3
systemctl enable wg-quick@wg3

# Проверка связности
ping 10.0.0.1  # Germany
ping 10.0.0.2  # Amsterdam
ping 10.0.0.5  # Oslo

# Проверка статуса туннеля
wg show
```

---

## Этап 3: Развёртывание HAProxy

### 3.1 Конфигурация

```bash
# На Germany load balancer
cd /etc/haproxy

# Бэкап дефолтного конфига
cp haproxy.cfg haproxy.cfg.backup

# Скопируйте ваш санитизированный конфиг
# Замените плейсхолдеры:
# - IP backend'ов (10.0.0.2, 10.0.0.5)
# - Пароль stats

nano haproxy.cfg
```

### 3.2 Запуск HAProxy

```bash
# Проверка конфигурации
haproxy -c -f /etc/haproxy/haproxy.cfg

# Если валидна, перезапуск
systemctl restart haproxy
systemctl enable haproxy

# Проверка статуса
systemctl status haproxy

# Просмотр логов
tail -f /var/log/haproxy.log
```

### 3.3 Проверка балансировки

```bash
# Проверка stats страницы
curl http://localhost:447

# Или в браузере:
# http://<GERMANY_PUBLIC_IP>:447
# Логин: admin / <your_password>

# Проверка связности с backend'ами
echo "show servers state" | socat stdio /run/haproxy/admin.sock
```

---

## Этап 4: Настройка мониторинга

### 4.1 Развёртывание Prometheus Stack (SPB)

```bash
# На SPB monitoring server
mkdir -p /opt/monitoring
cd /opt/monitoring

# Копируем конфиги из репозитория
cp -r spb-monitoring/configs/* .

# Редактируем prometheus.yml с реальными IP
nano prometheus.yml

# Заменяем 'hidden' плейсхолдеры на реальные IP
```

### 4.2 Запуск стека мониторинга

```bash
cd /opt/monitoring

# Запуск сервисов
docker-compose -f monitoring-docker-compose.yml up -d

# Проверка логов
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Проверка статуса
docker-compose ps
```

### 4.3 Доступ к Grafana

```bash
# Grafana доступна по адресу:
# http://<SPB_SERVER_IP>:3000

# Логин по умолчанию: admin / admin
# Измените пароль при первом входе!
```

---

## Этап 5: Настройка Firewall

### 5.1 Germany Load Balancer

```bash
apt install -y ufw

# Настройка правил
ufw allow 443/tcp          # HAProxy публичный
ufw allow 447/tcp          # HAProxy stats
ufw allow 448/tcp          # Prometheus exporter
ufw allow 51820/udp        # WireGuard wg0
ufw allow 51823/udp        # WireGuard wg3
ufw allow 8443/tcp         # Node Exporter
ufw allow 22/tcp           # SSH

# Включение
ufw enable
ufw status
```

### 5.2 Oslo & Amsterdam Endpoints

```bash
ufw allow 449/tcp from 10.0.0.0/24   # VLESS только от LB
ufw allow 51820/udp                   # WireGuard
ufw allow 51823/udp                   # WireGuard (Oslo)
ufw allow 8443/tcp from 10.0.0.0/24  # Node Exporter
ufw allow 22/tcp                      # SSH

ufw enable
```

### 5.3 SPB Monitoring Server

```bash
ufw allow from 10.0.0.0/24  # Разрешить от VPN
ufw allow 22/tcp from <YOUR_ADMIN_IP>  # SSH от конкретного IP
ufw default deny incoming

ufw enable
```

---

## Этап 6: Проверка

### 6.1 Связность WireGuard

```bash
# С Germany LB, пингуем все узлы
ping -c 4 10.0.0.2  # Amsterdam
ping -c 4 10.0.0.5  # Oslo

# Проверка handshakes
wg show wg0 latest-handshakes
wg show wg3 latest-handshakes
```

### 6.2 Здоровье HAProxy Backend'ов

```bash
# Проверка статуса backend'ов
echo "show servers state" | socat stdio /run/haproxy/admin.sock

# Ожидаемый вывод: серверы должны быть UP
# oslo-node: UP
# ams-node: UP
# local-backup: UP
```

### 6.3 Цели Prometheus

```bash
# Проверка targets в Prometheus
curl http://<SPB_SERVER>:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Все цели должны показывать: "health": "up"
```

### 6.4 End-to-End тест

```bash
# С внешнего клиента
curl -v https://<GERMANY_PUBLIC_IP>:443

# Должно подключиться через балансировщик к backend'у
# Проверьте логи HAProxy чтобы увидеть какой backend был выбран
```

---

## После развёртывания

### Усиление безопасности

- [ ] Измените все пароли по умолчанию
- [ ] Ротация ключей WireGuard
- [ ] Включите fail2ban для SSH
- [ ] Настройте автоматические обновления безопасности
- [ ] Пересмотрите и ограничьте правила firewall
- [ ] Настройте ротацию логов

### Настройка мониторинга

- [ ] Импортируйте Grafana дашборды
- [ ] Настройте правила алертов
- [ ] Протестируйте уведомления Telegram бота
- [ ] Настройте политики хранения бэкапов

---

## Откат при проблемах

Если развёртывание не удалось:

```bash
# Остановка HAProxy
systemctl stop haproxy

# Восстановление бэкапа конфига
cp /etc/haproxy/haproxy.cfg.backup /etc/haproxy/haproxy.cfg

# Перезапуск со старым конфигом
systemctl start haproxy

# Остановка WireGuard
wg-quick down wg0
wg-quick down wg3

# Остановка стека мониторинга
cd /opt/monitoring
docker-compose down
```

---

## Критерии успеха

Развёртывание успешно когда:

- [ ] Все WireGuard туннели UP
- [ ] HAProxy показывает все backend'ы как здоровые
- [ ] Prometheus успешно собирает все цели
- [ ] Grafana дашборды показывают метрики
- [ ] Алерты доставляются в Telegram
- [ ] End-to-end тест связности проходит
- [ ] Нет ошибок в логах
- [ ] Правила Firewall разрешают только необходимый трафик

---

**Развёртывание завершено! Ваша инфраструктура готова к production. 🎉**
