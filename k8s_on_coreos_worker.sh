MASTER_IP=$1
COREOS_IP=$2

echo "MASTER_IP: $1"
echo "COREOS_IP: $2"

echo 'Edit environment varible'
touch /etc/environment
cat << EOF > /etc/environment
COREOS_PRIVATE_IPV4=$COREOS_IP
COREOS_PUBLIC_IPV4=$COREOS_IP
EOF

echo 'Edit installation script'
sed -i "s/.*export ETCD_ENDPOINTS=.*/export ETCD_ENDPOINTS=http:\/\/$MASTER_IP:2379/g" /root/coreos-kubernetes/multi-node/generic/worker-install.sh
sed -i "s/.*export CONTROLLER_ENDPOINT=.*/export CONTROLLER_ENDPOINT=https:\/\/$MASTER_IP/g" /root/coreos-kubernetes/multi-node/generic/worker-install.sh


git clone -b 0.7.1 https://github.com/coreos/coreos-kubernetes.git
mkdir -p /etc/kubernetes/ssl/

echo "### need copy key ###"

sudo chmod 600 /etc/kubernetes/ssl/*-key.pem
sudo chown root:root /etc/kubernetes/ssl/*-key.pem

bash /root/coreos-kubernetes/multi-node/generic/worker-install.sh


