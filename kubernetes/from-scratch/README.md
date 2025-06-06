# Kubernetes Control Plane Bootstrap

This directory contains scripts to bootstrap a Kubernetes control plane with all necessary certificates and configurations.

## Prerequisites

- `openssl` for certificate generation
- `kubectl` for kubeconfig setup
- `sudo` access for modifying `/etc/hosts`

## Quick Start

Run the bootstrap script to generate all certificates and configurations:

```bash
./kube_bootstrap.sh
```

## Configuration

The script uses environment variables for configuration:

```bash
export MAIN_DIRECTORY="/tmp/kube"           # Main working directory
export PKI_DIRECTORY="/tmp/kube/pki"        # Certificate directory
export KUBECONFIG_DIRECTORY="/tmp/kube/configs"  # Kubeconfig directory
export SERVER_NAME="kube-apiserver.com"    # API server hostname
export SERVER_PORT="6443"                  # API server port
export CERT_DAYS="365"                     # Certificate validity period
```

## Running Control Plane Components

After running the bootstrap script, use these commands to start the control plane components:

### 1. etcd

```bash
etcd \
  --name default \
  --data-dir /tmp/etcd-data \
  --listen-client-urls http://127.0.0.1:2379 \
  --advertise-client-urls http://127.0.0.1:2379 \
  --listen-peer-urls http://127.0.0.1:2380 \
  --initial-advertise-peer-urls http://127.0.0.1:2380 \
  --initial-cluster default=http://127.0.0.1:2380 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster-state new
```

### 2. kube-apiserver

```bash
kube-apiserver \
  --bind-address=0.0.0.0 \
  --secure-port=6443 \
  --advertise-address=127.0.0.1 \
  --etcd-servers=http://127.0.0.1:2379 \
  --service-cluster-ip-range=10.96.0.0/16 \
  --service-account-key-file=/tmp/kube/pki/service-account-key.pem \
  --service-account-signing-key-file=/tmp/kube/pki/service-account-key.pem \
  --service-account-issuer=https://kubernetes.default.svc.cluster.local \
  --client-ca-file=/tmp/kube/pki/ca.crt \
  --tls-cert-file=/tmp/kube/pki/server.crt \
  --tls-private-key-file=/tmp/kube/pki/server.key \
  --kubelet-client-certificate=/tmp/kube/pki/server.crt \
  --kubelet-client-key=/tmp/kube/pki/server.key \
  --authorization-mode=Node,RBAC \
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --allow-privileged=true \
  --v=2
```

### 3. kube-controller-manager

```bash
kube-controller-manager \
  --kubeconfig=/tmp/kube/configs/kube-controller-manager.kubeconfig \
  --service-account-private-key-file=/tmp/kube/pki/service-account-key.pem \
  --root-ca-file=/tmp/kube/pki/ca.crt \
  --cluster-signing-cert-file=/tmp/kube/pki/ca.crt \
  --cluster-signing-key-file=/tmp/kube/pki/ca.key \
  --use-service-account-credentials=true \
  --v=2
```

### 4. kube-scheduler

```bash
kube-scheduler \
  --config=/tmp/kube/configs/kube-scheduler-config.yaml \
  --v=2
```

## Generated Files

The bootstrap script creates:

### Certificates (`/tmp/kube/pki/`)
- `ca.crt` / `ca.key` - Certificate Authority
- `server.crt` / `server.key` - API server certificate
- `kube-scheduler.crt` / `kube-scheduler.key` - Scheduler certificate
- `service-account.pem` / `service-account-key.pem` - Service account signing keys

### Kubeconfig Files (`/tmp/kube/configs/`)
- `kubeconfig` - Admin kubeconfig
- `kube-scheduler.kubeconfig` - Scheduler kubeconfig
- `kube-controller-manager.kubeconfig` - Controller manager kubeconfig
- `kube-scheduler-config.yaml` - Scheduler configuration

## Notes

- The script adds the server hostname to `/etc/hosts` pointing to `127.0.0.1`
- All certificates are valid for 365 days by default
- The setup is configured for a single-node control plane on localhost