#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/../../ansible"
SSH_KEY_PATH="${HOME}/.ssh/id_rsa"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Error: SSH private key not found at $SSH_KEY_PATH"
    exit 1
fi

echo "Fetching GCE instance IPs..."

CONTROL_PLANE_IPS=$(gcloud compute instances list \
    --filter="labels.component=control-plane-node AND status=RUNNING" \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)" | tr '\n' ' ')

WORKER_NODE_IPS=$(gcloud compute instances list \
    --filter="labels.component=worker-node AND status=RUNNING" \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)" | tr '\n' ' ')

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
ansible_user=ybquansah
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