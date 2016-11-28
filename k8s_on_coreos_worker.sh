BRANCH_TAG=$1
MASTER_IP=$2
COREOS_IP=$3

echo "MASTER_IP: $MASTER_IP"
echo "COREOS_IP: $COREOS_IP"

ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
ssh-copy-id -o StrictHostKeyChecking=no core_user@$MASTER_IP
mkdir -p /etc/kubernetes/ssl/
scp -o StrictHostKeyChecking=no core_user@$MASTER_IP:/etc/kubernetes/ssl/* /etc/kubernetes/ssl/

git clone -b $BRANCH_TAG https://github.com/coreos/coreos-kubernetes.git

echo 'Edit environment varible'
touch /etc/environment
cat << EOF > /etc/environment
COREOS_PRIVATE_IPV4=$COREOS_IP
COREOS_PUBLIC_IPV4=$COREOS_IP
EOF

echo 'Edit installation script'
sed -i "s/.*export ETCD_ENDPOINTS=.*/export ETCD_ENDPOINTS=http:\/\/$MASTER_IP:2379/g" /root/coreos-kubernetes/multi-node/generic/worker-install.sh
sed -i "s/.*export CONTROLLER_ENDPOINT=.*/export CONTROLLER_ENDPOINT=https:\/\/$MASTER_IP/g" /root/coreos-kubernetes/multi-node/generic/worker-install.sh

mkdir -p /etc/kubernetes/ssl/

echo "### need copy key ###"

chmod 600 /etc/kubernetes/ssl/*-key.pem
chown root:root /etc/kubernetes/ssl/*-key.pem

bash /root/coreos-kubernetes/multi-node/generic/worker-install.sh


