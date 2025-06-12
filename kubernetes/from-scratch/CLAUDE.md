# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Kubernetes control plane bootstrap project that creates certificates and configurations for running Kubernetes components from scratch. The project is designed for single-node control plane setup on localhost for learning and development purposes.

## Key Commands

### Bootstrap the Kubernetes Control Plane
```bash
./kube_bootstrap.sh
```

This script generates all necessary certificates, kubeconfig files, and configurations for running Kubernetes control plane components.

### Environment Configuration
The bootstrap script uses these environment variables:
- `MAIN_DIRECTORY` (default: `/tmp/kube`) - Main working directory
- `PKI_DIRECTORY` (default: `$MAIN_DIRECTORY/pki`) - Certificate directory  
- `KUBECONFIG_DIRECTORY` (default: `$MAIN_DIRECTORY/configs`) - Kubeconfig directory
- `SERVER_NAME` (default: `kube-apiserver.com`) - API server hostname
- `SERVER_PORT` (default: `6443`) - API server port
- `CERT_DAYS` (default: `365`) - Certificate validity period

### Starting Control Plane Components
After running the bootstrap script, start components in this order:

1. **etcd**: `etcd --name default --data-dir /tmp/etcd-data --listen-client-urls http://127.0.0.1:2379 --advertise-client-urls http://127.0.0.1:2379 --listen-peer-urls http://127.0.0.1:2380 --initial-advertise-peer-urls http://127.0.0.1:2380 --initial-cluster default=http://127.0.0.1:2380 --initial-cluster-token etcd-cluster-1 --initial-cluster-state new`

2. **kube-apiserver**: Uses certificates from `/tmp/kube/pki/` and connects to etcd on port 2379

3. **kube-controller-manager**: Uses kubeconfig from `/tmp/kube/configs/kube-controller-manager.kubeconfig`

4. **kube-scheduler**: Uses config from `/tmp/kube/configs/kube-scheduler-config.yaml`

## Architecture

### Certificate Management
The bootstrap script creates a complete PKI infrastructure:
- Self-signed CA certificate for the cluster
- Server certificates for API server communication
- Component-specific certificates for scheduler and controller manager
- Service account signing keys for token generation

### Configuration Generation
- Generates kubeconfig files for each component with embedded certificates
- Creates scheduler configuration file with proper client connection settings
- Automatically configures cluster endpoints and authentication

### File Structure
- `/tmp/kube/pki/` - All certificates and keys
- `/tmp/kube/configs/` - Kubeconfig files and component configurations
- Script modifies `/etc/hosts` to map server hostname to localhost

## Development Notes

- The project is designed for localhost development with hardcoded IPs (127.0.0.1)
- All certificates are self-signed and valid for 365 days by default
- The bootstrap script is idempotent and can be re-run safely
- KUBECONFIG environment variable is automatically exported after bootstrap