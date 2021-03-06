#!/bin/sh

BRANCH_VERSION=$1
PUBLIC_IPV4=$2

git clone -b $BRANCH_VERSION https://github.com/coreos/coreos-kubernetes.git

echo "BRANCH_VERSION: $1"
echo "PUBLIC_IPV4: $2"

echo 'Edit environment varible'
touch /etc/environment
cat << EOF > /etc/environment
COREOS_PRIVATE_IPV4=$PUBLIC_IPV4
COREOS_PUBLIC_IPV4=$PUBLIC_IPV4
EOF
echo 'Done'

echo 'Setup etcd'
mkdir -p /etc/systemd/system/etcd2.service.d
touch /etc/systemd/system/etcd2.service.d/40-listen-address.conf
cat << EOF > /etc/systemd/system/etcd2.service.d/40-listen-address.conf
[Service]
Environment=ETCD_LISTEN_CLIENT_URLS=http://$PUBLIC_IPV4:2379
Environment=ETCD_ADVERTISE_CLIENT_URLS=http://$PUBLIC_IPV4:2379
EOF
echo 'Done'

systemctl stop etcd2
systemctl start etcd2
systemctl enable etcd2

echo 'Generate keys'
mkdir -p /root/keys
cd /root/keys
echo 'Generate CA'
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 1826 -out ca.pem -subj "/CN=kube-ca"
echo 'Generate openssl config'
touch openssl.cnf
cat << EOF > /root/keys/openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
IP.1 = $PUBLIC_IPV4
EOF
echo 'Done'

echo 'Generate apiserver key'
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

echo 'Generate worker key'
openssl genrsa -out worker-key.pem 2048
openssl req -new -key worker-key.pem -out worker.csr -subj "/CN=kube-worker"
openssl x509 -req -in worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker.pem -days 365

echo 'Generate admin key'
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365

echo 'chmod *key'
mkdir -p /etc/kubernetes/ssl
cp -r /root/keys/* /etc/kubernetes/ssl
chmod 600 /etc/kubernetes/ssl/*-key.pem
chown root:root /etc/kubernetes/ssl/*-key.pem
chmod +r /etc/kubernetes/ssl/worker-key.pem

echo 'Edit installation script'
sed -i "s/.*export ETCD_ENDPOINTS=.*/export ETCD_ENDPOINTS=http:\/\/$PUBLIC_IPV4:2379/g" /root/coreos-kubernetes/multi-node/generic/controller-install.sh

echo 'Start deploy kubernetes'
bash /root/coreos-kubernetes/multi-node/generic/controller-install.sh

echo 'Install kubectl'
cd ~/
curl -O https://storage.googleapis.com/kubernetes-release/release/v1.4.3/bin/linux/amd64/kubectl
chmod +x kubectl
echo 'Cinfigure kubectl'
~/kubectl config set-cluster default-cluster --server=https://$PUBLIC_IPV4 --certificate-authority=keys/ca.pem
~/kubectl config set-credentials default-admin --certificate-authority=keys/ca.pem --client-key=keys/admin-key.pem --client-certificate=keys/admin.pem
~/kubectl config set-context default-system --cluster=default-cluster --user=default-admin
~/kubectl config use-context default-system

echo 'Marking Master node be schedulable'
./kubectl patch node $PUBLIC_IPV4 -p '{"spec":{"unschedulable":false}}'
