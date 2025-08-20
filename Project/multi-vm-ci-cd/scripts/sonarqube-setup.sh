#!/bin/bash
set -e

# 1. System tuning
echo "[INFO] Configuring system limits..."
cp /etc/sysctl.conf /root/sysctl.conf_backup
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
sysctl -p

cp /etc/security/limits.conf /root/limits.conf.bak
cat <<EOF | sudo tee /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOF

# 2. Java 17 Installation
echo "[INFO] Installing Java 17..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk unzip wget curl net-tools gnupg

# 3. PostgreSQL installation & configuration
echo "[INFO] Installing PostgreSQL..."
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib

echo "[INFO] Configuring PostgreSQL for SonarQube..."
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# 4. SonarQube Installation
echo "[INFO] Downloading and installing SonarQube..."
SONAR_VERSION=25.7.0.110598

SONAR_DIR=/opt/sonarqube
sudo mkdir -p /tmp/sonar && cd /tmp/sonar
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip
unzip -o sonarqube-${SONAR_VERSION}.zip
sudo mv sonarqube-${SONAR_VERSION} ${SONAR_DIR}

# Create sonar user
echo "[INFO] Creating sonar user..."
sudo groupadd -f sonar
id -u sonar &>/dev/null || sudo useradd -c "SonarQube User" -d ${SONAR_DIR} -g sonar sonar
sudo chown -R sonar:sonar ${SONAR_DIR}

# Configure SonarQube
echo "[INFO] Configuring SonarQube..."
cp ${SONAR_DIR}/conf/sonar.properties /root/sonar.properties.backup
cat <<EOT | sudo tee ${SONAR_DIR}/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube

sonar.web.host=0.0.0.0
sonar.web.port=9000

sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT

# 5. Systemd service
echo "[INFO] Creating SonarQube systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=network.target postgresql.service

[Service]
Type=forking
ExecStart=${SONAR_DIR}/bin/linux-x86-64/sonar.sh start
ExecStop=${SONAR_DIR}/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=on-failure
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

# 6. NGINX as Reverse Proxy
echo "[INFO] Installing and configuring NGINX..."
sudo apt-get install -y nginx

# Remove default page
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default

# Configure reverse proxy
cat <<EOF | sudo tee /etc/nginx/sites-available/sonarqube
server {
    listen 80;
    server_name sonarqube.groophy.in;

    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;

    location / {
        proxy_pass         http://127.0.0.1:9000;
        proxy_redirect     off;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto http;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
sudo systemctl enable nginx
sudo systemctl restart nginx

# 7. Firewall rules (if UFW is enabled)
if sudo ufw status | grep -q active; then
  sudo ufw allow 80/tcp
  sudo ufw allow 9000/tcp
  sudo ufw allow 9001/tcp
fi

# 8. Final Check
echo "[INFO] Waiting for SonarQube to start..."
sleep 20
if sudo systemctl is-active --quiet sonarqube; then
  echo "✅ SonarQube is running. Access it via http://<your-server-ip> or http://sonarqube.groophy.in"
else
  echo "❌ SonarQube failed to start. Check logs in ${SONAR_DIR}/logs"
fi
