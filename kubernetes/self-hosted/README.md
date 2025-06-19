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
