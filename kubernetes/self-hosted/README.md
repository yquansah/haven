## 06/07/2025

## 06/08/2025

## 06/09/2025

## 06/10/2025

## 06/12/2025

### Dev Log
- **Restructured project organization**: Renamed `raspberry-pi` directory to `self-hosted` to better reflect multi-architecture support
- **Enhanced kubeadm script for multi-architecture support**: 
  - Added automatic architecture detection (x86_64 → amd64, aarch64 → arm64)
  - Modified CNI plugin downloads to use architecture-specific binaries
  - Script now works seamlessly on both AMD64 and ARM64 systems
- **Added Ansible automation setup**:
  - Created `ansible.cfg` configuration file
  - Set up inventory file for managing multiple nodes
  - Added `kubeadm-setup.yml` playbook for automated cluster deployment
  - Included password file for authentication
- **Organized Kubernetes manifests**: Moved utility manifests to `useful-manifests/` directory for better organization
- **Documentation cleanup**: Removed old README from `from-scratch` and added CLAUDE.md for context

### Initial Steps
- Researched on running `kubeadm` on Raspberry Pi's, and found this great [medium article](https://medium.com/@bsatnam98/setup-of-a-kubernetes-cluster-v1-29-on-raspberry-pis-a95b705c04c1)

### Problems
- I ran into some cgroup issues with the Raspberry Pi's where the kernel does not enable memory cgroups by default, and was able to fix this by enabling cgroups in the boot config
- I also ran an issue of `kubeadm` using the `containerd` socket by default when trying to pull images, so I had to adjust my script to use `--cri-socket=/var/run/crio/crio.sock`

### Results
- My kubernetes cluster is up and running now!
```
$ kubectl get nodes
NAME               STATUS   ROLES           AGE   VERSION
raspberrypi        Ready    control-plane   34m   v1.30.0
raspberrypi-dos    Ready    <none>          13m   v1.30.0
raspberrypi-tres   Ready    <none>          96s   v1.30.0
```

