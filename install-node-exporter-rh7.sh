#!/bin/bash
#
# install-node-exporter-rh7.sh -- Automatically install Node exporter on
# RedHat version 7 distributions with "systemd" Linux initialization system.
#
# (C) Copyright 2019, Maxence Grymonprez <maxgrymonprez@live.fr>
#
# install-node-exporter-rh7.sh is free software: you can redistribute
# it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# install-node-exporter-rh7.sh is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with help.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Usage:
#   ./install-node-exporter-rh7.sh
# Note:
#   Requires a user with highest permissions

# You can replace the version number and the architecture name.
# Find out the latest release of Node exporter on the official
# GitHub repository: https://github.com/prometheus/node_exporter/releases
# Version of Node Exporter
version="1.0.1"
# System architecture
arch="amd64"

# Change location
cd /usr/local/bin

# Check if Node Exporter is already in place
if [ -f node_exporter ]; then
    echo "node_exporter already exists in /usr/local/bin"
    exit 1
fi

# Download Node Exporter
curl -LO https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-$arch.tar.gz

# Extract node_exporter binary from archive
tar -xvf node_exporter-$version.linux-$arch.tar.gz node_exporter-$version.linux-$arch/node_exporter --strip-components 1

# Remove archive
rm node_exporter-$version.linux-$arch.tar.gz

# Create local user
useradd -rs /bin/false node_exporter

# Set owner and permissions on binary file
chown node_exporter:node_exporter node_exporter
chmod o-x node_exporter

# Create service file
cat > /etc/systemd/system/node_exporter.service << EOL
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOL

# Reload the system daemon
systemctl daemon-reload

# Enable service at startup
systemctl enable node_exporter

# Add firewalld rules
firewall-cmd --permanent --new-service=node_exporter
firewall-cmd --permanent --service=node_exporter --set-short="Node Exporter Service Ports"
firewall-cmd --permanent --service=node_exporter --set-description="Node Exporter service firewalld port exceptions"
firewall-cmd --permanent --service=node_exporter --add-port=9100/tcp
firewall-cmd --permanent --add-service=node_exporter
firewall-cmd --reload

# Start Service
systemctl start node_exporter