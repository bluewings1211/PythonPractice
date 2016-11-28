echo "INTERFACE: $1"
echo "ADDRESS: $2"
echo "GATEWAY: $3"

touch /etc/systemd/network/$1.network
cat << EOF > /etc/systemd/network/$1.network

[Match]
Name=$1

[Network]
Address=$2
Gateway=$3
DNS=8.8.8.8
EOF

systemctl restart systemd-networkd
