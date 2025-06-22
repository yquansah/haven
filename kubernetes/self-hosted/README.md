# Self-Hosted Kubernetes

This directory contains configurations and scripts for deploying self-hosted Kubernetes clusters in different environments.

## Directory Structure

### `cloud/aws/`
AWS-based Kubernetes deployment using Terraform:
- **Terraform Infrastructure**: EC2 instances, load balancers, VPC configuration
- **Setup Scripts**: Automated deployment and configuration
- **Makefile**: Build and deployment automation

### `on-prem/`
On-premises Kubernetes deployment tools:
- **Ansible**: Automated cluster provisioning with kubeadm
  - `kubeadm-setup.yml` - Playbook for cluster initialization
  - `inventory.ini` - Host configuration
- **Manual Scripts**: `kubeadm-init.sh` for direct cluster setup

Both deployment methods provide complete Kubernetes cluster setup with proper networking and security configurations.

## Bootstrapping a Kubernetes Cluster with kubeadm

### Control Plane Node Initialization

To bootstrap the control plane node, run `kubeadm init` with appropriate configuration:

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<CONTROL_PLANE_IP>
```

Key parameters:
- `--pod-network-cidr`: CIDR range for pod networking (adjust based on your CNI choice)
- `--apiserver-advertise-address`: IP address the API server will advertise (use the control plane node's IP)

After successful initialization:
1. Configure kubectl for the current user:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

2. Install a CNI plugin (e.g., Calico):
   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

### Joining Worker Nodes

After control plane initialization, `kubeadm init` outputs a join command. On each worker node, run:

```bash
sudo kubeadm join <CONTROL_PLANE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

If you need to regenerate the join command:
```bash
kubeadm token create --print-join-command
```

Verify nodes have joined successfully:
```bash
kubectl get nodes
```
