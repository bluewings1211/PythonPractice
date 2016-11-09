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
sed -i "s/.*export CONTROLLER_ENDPOINTS=.*/export CONTROLLER_ENDPOINTS=https:\/\/$MASTER_IP/g" /root/coreos-kubernetes/multi-node/generic/worker-install.sh


git clone https://github.com/coreos/coreos-kubernetes.git
git checkout v0.7.1
mkdir -p /etc/kubernetes/ssl/

### need copy key ###

sudo chmod 600 /etc/kubernetes/ssl/*-key.pem
sudo chown root:root /etc/kubernetes/ssl/*-key.pem

bash multi-node/generic/worker-install.sh
~/kubectl config set-cluster default-cluster --server=https://${MASTER_IP} --certificate-authority=ca.pem
~/kubectl config set-credentials default-admin --certificate-authority=ca.pem --client-key=admin-key.pem --client-certificate=admin.pem
~/kubectl config set-context default-system --cluster=default-cluster --user=default-admin
~/kubectl config use-context default-system
