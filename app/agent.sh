#!/bin/bash
# ==========================================
# SaaS Server Monitoring Agent Installer
# ==========================================
set -e

# 1. Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Пожалуйста, запустите скрипт от имени root (sudo)"
  exit 1
fi

# 2. Парсинг аргументов
TOKEN=""
for arg in "$@"; do
  case $arg in
    --token=*)
      TOKEN="${arg#*=}"
      shift
      ;;
  esac
done

if [ -z "$TOKEN" ]; then
  echo "❌ Ошибка: Не указан токен. Скопируйте полную команду из панели управления."
  exit 1
fi

echo "🚀 Установка агента мониторинга для токена: $TOKEN..."

# 3. Скачивание Promtail (сборщик логов)
PROMTAIL_VERSION="2.9.3"
echo "⬇️ Скачивание агента v$PROMTAIL_VERSION..."
curl -sLO "https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"
unzip -q promtail-linux-amd64.zip
mv promtail-linux-amd64 /usr/local/bin/promtail
chmod +x /usr/local/bin/promtail
rm promtail-linux-amd64.zip

# 4. Создание пользователя для безопасности
if ! id -u promtail > /dev/null 2>&1; then
    useradd --system --no-create-home --shell /bin/false promtail
fi

# Даем права на чтение системных логов (Ubuntu/Debian/CentOS)
usermod -a -G adm promtail || true

# 5. Создание конфигурации Promtail
echo "⚙️ Настройка конфигурации..."
mkdir -p /etc/promtail
cat <<EOF > /etc/promtail/config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: https://logs.inv.e-laba52.ru/loki/api/v1/push
    tenant_id: "${TOKEN}" # Строгая изоляция логов по токену сервера

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*.log
  - job_name: auth
    static_configs:
      - targets:
          - localhost
        labels:
          job: auth
          __path__: /var/log/auth.log
EOF

chown -R promtail:promtail /etc/promtail

# 6. Создание службы systemd
echo "🔄 Настройка автозапуска..."
cat <<EOF > /etc/systemd/system/promtail.service
[Unit]
Description=Promtail Log Collector
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/config.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 7. Запуск службы
systemctl daemon-reload
systemctl enable promtail
systemctl start promtail

echo "✅ Агент успешно установлен и запущен!"
echo "📊 Логи начнут поступать в систему в течение минуты."
```
