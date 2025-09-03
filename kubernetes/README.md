# Kubernetes

This is a directory dedicated to all things Kubernetes.

## Different Distributions

### YKE
YKE (Yoofi's Kubernetes Engine) is a distribution created by me. It focuses on simple semantics of running various workloads that we encounter everyday as self-hosted Kubernetes clusters on various clouds using the cloud's version of a VM. So EC2 for AWS, Compute Engine for GKE, etc.

In order for YKE to work on a specific cloud, the cloud would have to support a way for the cluster to provision Persistent Volumes, and Ingress into the cluster via Layer 4 load balancers. As you provision the cluster, it comes with a variety of opinionated software including `cert-manager`, `traefik`, etc.

The configuration for a YKE cluster is in the [self hosted directory](./self-hosted/).

### GKE
GKE (Google's Kubernetes Engine) is Google's distribution of Kubernetes. It comes with standard mode and Autopilot mode which reminds me of serverless workloads.

Autopilot benefits:
- Allows you to just pay for the resources that your workloads use rather than the fees for the Compute Engine nodes themselves
- Google manages the underlying compute for you so you can focus on deploying apps, and not worry about infrastructure
- GKE automatically scales nodes for you as you horizontally scale Pods
- Google automatically applies security patches for your nodes when available, fully managed

Google charges $0.10 per hour per GKE cluster. With standard mode you pay for the maintanence cost of the cluster while paying for the costs of the worker nodes which are just Compute Engine instances at the end of the day.
