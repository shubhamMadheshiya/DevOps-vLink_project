#!/bin/bash
# This script automates the installation and configuration of Nexus Repository Manager 3.x
# on a CentOS/RHEL-based Linux server using yum.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Nexus Repository Manager installation script..."
echo "-------------------------------------------------------"

# --- Step 1: Login to your Linux server and update yum packages. Also install required utilities. ---
echo "Step 1: Updating system packages and installing required utilities..."
sudo yum update -y
sudo yum install wget -y
sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo yum install net-tools -y # Required for netstat

echo "Java version installed:"
java -version
echo "-------------------------------------------------------"

# --- Step 2: Download the latest Nexus. ---
echo "Step 2: Downloading and extracting the latest Nexus Repository Manager..."
NEXUS_INSTALL_DIR="/opt"
NEXUS_DATA_DIR="/opt/nexusdata"

cd "$NEXUS_INSTALL_DIR"

# Download the specified Nexus Unix archive
echo "Downloading Nexus from https://download.sonatype.com/nexus/3/nexus-3.82.0-08-linux-x86_64.tar.gz..."
sudo wget -O latest-unix.tar.gz https://download.sonatype.com/nexus/3/nexus-3.82.0-08-linux-x86_64.tar.gz

# Extract the archive
echo "Extracting Nexus archive..."
sudo tar -xvzf latest-unix.tar.gz

# Find the extracted directory (e.g., nexus-3.x.x-xx) and rename it to 'nexus'
NEXUS_EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "nexus-3*" | head -n 1)
if [ -z "$NEXUS_EXTRACTED_DIR" ]; then
    echo "Error: Nexus extracted directory not found."
    exit 1
fi

echo "Renaming $NEXUS_EXTRACTED_DIR to nexus..."
sudo mv "$NEXUS_EXTRACTED_DIR" nexus

# Create nexusdata directory and move sonatype-work into it
echo "Creating nexusdata directory and moving sonatype-work..."
sudo mkdir -p "$NEXUS_DATA_DIR"
sudo mv sonatype-work "$NEXUS_DATA_DIR"/nexus3

# Clean up the downloaded tarball
echo "Cleaning up downloaded tarball..."
sudo rm latest-unix.tar.gz

echo "Nexus installed to: $NEXUS_INSTALL_DIR/nexus"
echo "Nexus data directory: $NEXUS_DATA_DIR/nexus3"
echo "Contents of $NEXUS_INSTALL_DIR:"
ls -lh "$NEXUS_INSTALL_DIR"
echo "-------------------------------------------------------"

# --- Step 3: Set User/Permissions and Configurations ---
echo "Step 3: Setting user, permissions, and configurations..."

# Create nexus user
echo "Creating system user 'nexus'..."
sudo useradd --system --no-create-home nexus

# Set permissions
echo "Setting permissions for nexus directories..."
sudo chown -R nexus:nexus "$NEXUS_INSTALL_DIR"/nexus
sudo chown -R nexus:nexus "$NEXUS_DATA_DIR"/nexus3

# Edit /opt/nexus/bin/nexus.vmoptions file
echo "Configuring nexus.vmoptions..."
NEXUS_VMOPTIONS_FILE="$NEXUS_INSTALL_DIR/nexus/bin/nexus.vmoptions"
sudo tee "$NEXUS_VMOPTIONS_FILE" > /dev/null <<EOF
-Xms2703m
-Xmx2703m
-XX:MaxDirectMemorySize=2703m
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=../nexusdata/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=../nexusdata/nexus3
-Dkaraf.log=../nexusdata/nexus3/log
-Djava.io.tmpdir=../nexusdata/nexus3/tmp
-Dkaraf.startLocalConsole=false
EOF
echo "Updated $NEXUS_VMOPTIONS_FILE"

# Edit nexus.rc file
# echo "Configuring nexus.rc..."
# NEXUS_RC_FILE="$NEXUS_INSTALL_DIR/nexus/bin/nexus.rc"
# sudo sed -i 's/^#run_as_user=""/run_as_user="nexus"/' "$NEXUS_RC_FILE"
# echo "Updated $NEXUS_RC_FILE"

# Modify the nexus-default.properties file
echo "Configuring nexus-default.properties..."
NEXUS_DEFAULT_PROPERTIES_FILE="$NEXUS_INSTALL_DIR/nexus/etc/nexus-default.properties"
sudo sed -i 's/^application-host=.*/application-host=0.0.0.0/' "$NEXUS_DEFAULT_PROPERTIES_FILE"
sudo sed -i 's/^application-port=.*/application-port=9081/' "$NEXUS_DEFAULT_PROPERTIES_FILE"
echo "Updated $NEXUS_DEFAULT_PROPERTIES_FILE"

# Configure the open file limit of the nexus user.
echo "Configuring open file limits for nexus user..."
LIMITS_CONF_FILE="/etc/security/limits.conf"
if ! grep -q "nexus - nofile 65536" "$LIMITS_CONF_FILE"; then
    echo "nexus - nofile 65536" | sudo tee -a "$LIMITS_CONF_FILE" > /dev/null
    echo "Added open file limit to $LIMITS_CONF_FILE"
else
    echo "Open file limit for nexus user already configured in $LIMITS_CONF_FILE"
fi
echo "-------------------------------------------------------"

# --- Step 4: Set Nexus as a System Service ---
echo "Step 4: Setting Nexus as a System Service..."

# Create the Systemd service file
NEXUS_SERVICE_FILE="/etc/systemd/system/nexus.service"
echo "Creating systemd service file: $NEXUS_SERVICE_FILE"
sudo tee "$NEXUS_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Nexus Service
After=syslog.target network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Group=nexus
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
echo "Created $NEXUS_SERVICE_FILE"

# Manage Nexus Service
echo "Reloading systemd daemon, enabling and starting Nexus service..."
sudo systemctl daemon-reload
sudo systemctl enable nexus.service
sudo systemctl start nexus.service

echo "-------------------------------------------------------"
echo "Nexus Repository Manager installation and configuration complete!"
echo "Please wait a few minutes for Nexus to start up completely."
echo "You can monitor the log file using:"
echo "tail -f /opt/nexusdata/nexus3/log/nexus.log"
echo ""
echo "Once started, check the running service port (should be 9081):"
echo "netstat -tunlp | grep 9081"
echo ""
echo "To get the default admin password for first login:"
echo "cat /opt/nexusdata/nexus3/admin.password"
echo ""
echo "You should be able to access Nexus in your browser at: http://<your_server_ip_or_hostname>:9081"