#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/../../ansible"
SSH_KEY_PATH="${HOME}/.ssh/id_rsa"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Error: SSH private key not found at $SSH_KEY_PATH"
    exit 1
fi

echo "Fetching EC2 instance IPs..."

CONTROL_PLANE_IPS=$(aws ec2 describe-instances \
    --filters "Name=tag:Component,Values=control-plane-node" "Name=instance-state-name,Values=running" \
    --output text \
    --query "Reservations[].Instances[].PublicIpAddress" | tr '\n' ' ')

WORKER_NODE_IPS=$(aws ec2 describe-instances \
    --filters "Name=tag:Component,Values=worker-node" "Name=instance-state-name,Values=running" \
    --output text \
    --query "Reservations[].Instances[].PublicIpAddress" | tr '\n' ' ')

if [ -z "$CONTROL_PLANE_IPS" ] && [ -z "$WORKER_NODE_IPS" ]; then
    echo "Error: No control plane or worker nodes found"
    exit 1
fi

echo "Found control plane nodes: $CONTROL_PLANE_IPS"
echo "Found worker nodes: $WORKER_NODE_IPS"

TEMP_INVENTORY=$(mktemp)
cat > "$TEMP_INVENTORY" << EOF
[control-plane]
EOF

i=1
for ip in $CONTROL_PLANE_IPS; do
    echo "control-plane-$i ansible_host=$ip" >> "$TEMP_INVENTORY"
    ((i++))
done

cat >> "$TEMP_INVENTORY" << EOF

[worker-nodes]
EOF

i=1
for ip in $WORKER_NODE_IPS; do
    echo "worker-node-$i ansible_host=$ip" >> "$TEMP_INVENTORY"
    ((i++))
done

cat >> "$TEMP_INVENTORY" << EOF

[kube-nodes:children]
control-plane
worker-nodes

[kube-nodes:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=$SSH_KEY_PATH
ansible_become=yes
EOF

echo "Generated inventory:"
cat "$TEMP_INVENTORY"
echo

echo "Running ansible playbook..."
cd "$ANSIBLE_DIR"
ansible-playbook -i "$TEMP_INVENTORY" kubeadm-setup.yml

rm "$TEMP_INVENTORY"
echo "Ansible playbook completed successfully!"

# sudo kubeadm init --control-plane-endpoint="$LOAD_BALANCER_HOST:$LOAD_BALANCER_PORT" --apiserver-cert-extra-sans="$LOAD_BALANCER_HOST" --pod-network-cidr="192.168.0.0/16" --node-name "$NODENAME" --ignore-preflight-errors Swap
# sudo kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://docs.projectcalico.org/manifests/calico.yaml
# sudo kubeadm token create --print-join-command > command.txt
