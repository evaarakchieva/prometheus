#!/bin/bash
VERSION_PROMETHEUS="2.51.2"
CONFIG_FOLDER_PROMETHEUS="/etc/prometheus"
TSDATA_FOLDER_PROMETHEUS="/etc/prometheus/data"

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.51.2/prometheus-2.51.2.linux-amd64.tar.gz
tar xvfz prometheus-$VERSION_PROMETHEUS.linux-amd64.tar.gz
cd prometheus-$VERSION_PROMETHEUS.linux-amd64

mkdir -p $CONFIG_FOLDER_PROMETHEUS
mkdir -p $TSDATA_FOLDER_PROMETHEUS

mv prometheus /usr/bin/
rm -rf /tmp/prometheus*

#-----------------------------------------
#
# prometheus configuration
#
#-----------------------------------------

cat <<EOF> $CONFIG_FOLDER_PROMETHEUS/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name      : "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

useradd -rs /bin/false prometheus
chown prometheus:prometheus /usr/bin/prometheus
chown prometheus:prometheus $CONFIG_FOLDER_PROMETHEUS
chown prometheus:prometheus $CONFIG_FOLDER_PROMETHEUS/prometheus.yml
chown prometheus:prometheus $TSDATA_FOLDER_PROMETHEUS



#-----------------------------------------
#
# prometheus as Linux service
#
#-----------------------------------------

cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file       ${CONFIG_FOLDER_PROMETHEUS}/prometheus.yml \
  --storage.tsdb.path ${TSDATA_FOLDER_PROMETHEUS}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus --no-pager
prometheus --version
