#!/bin/bash
#
# For RedHat version 6 distributions with "init" Linux initialization system.

# Version of Node Exporter
version="0.18.1"
# System architecture
arch="amd64"

# Change location
cd /usr/local/bin

# Check if Node Exporter is already in place
if [ -f node_exporter ]; then
    echo "node_exporter already exists in /usr/local/bin"
    exit 1
fi

# Download Node Exporter for Linux 64-bit
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

# Create log file
touch /var/log/node_exporter.log

# Set owner and permissions on log file
chmod 640 /var/log/node_exporter.log
chown node_exporter:node_exporter /var/log/node_exporter.log

# Create log rotation file
cat > /etc/logrotate.d/node_exporter << EOL
/var/log/node_exporter.log {
    weekly
    missingok
    notifempty
    compress
    delaycompress
    create 640 node_exporter adm
}
EOL

# Create service file
cat > /etc/init.d/node_exporter << \EOL
#!/bin/bash
#
# httpd        Startup script for the Node Exporter
#
# chkconfig: 345 70 30
# description: The Node Exporter collects system metrics for Prometheus.
# processname: node_exporter
# pidfile: /var/run/node_exporter.pid
#
### BEGIN INIT INFO
# Provides: node_exporter
# Required-Start:
# Required-Stop:
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Should-Start:
# Short-Description: start and stop Node Exporter
# Description: The Node Exporter collects system metrics for Prometheus.
### END INIT INFO

# Source function library.
source /etc/init.d/functions

node_exporter=/usr/local/bin/node_exporter
prog=node_exporter
user=node_exporter
pidfile=/var/run/node_exporter.pid
logfile=/var/log/node_exporter.log
RETVAL=0

start() {
	echo -n "Starting $prog: "
	daemon --user "$user" --pidfile="$pidfile" "$node_exporter &>$logfile &"
	RETVAL=$?
	echo $(pidofproc $prog) > $pidfile
	echo
	return $RETVAL
}

stop() {
	echo -n "Shutting down $prog: "
	killproc -p "$pidfile" $prog
	RETVAL=$?
	echo
	rm -f $pidfile
	return $RETVAL
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		stop
		start
		;;
	*)
		echo "Usage: $prog {start|stop|restart}"
		RETVAL=2
esac

exit $RETVAL
EOL

# Set permissions on service file
chmod 755 /etc/init.d/node_exporter

# Enable service at startup
chkconfig node_exporter --add

# Add iptables rules
iptables -I INPUT -p tcp --dport 9100 -j ACCEPT
service iptables save

# Start service
service node_exporter start
