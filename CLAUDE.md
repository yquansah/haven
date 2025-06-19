Haven is a central collection of utilities, best practices, and learnings from personal industry experience related to general computing. It is a best effort in being agnostic for particular technologies, and serve as a jumping ground for deploying, operating, monitoring, and troubleshooting large scale systems.

The repository is split up into the following sections:

1. [compute](./compute/)
2. [kubernetes](./kubernetes/)
This section intends to show how to deploy Kubernetes in various ways. It has tooling for deploying to an on-prem setup, VM(s) on a cloud, and cloud managed Kubernetes offerings. There is also a [section](./kubernetes/useful-manifests/) that includes useful Kubernetes manifests for experimenting with your cluster. The goal of these manifests is to try and simulate large scale issues on a smaller scale to gain the intuition on how to operate Kubernetes clusters seamlessly.
3. [memory](./memory/)
4. [network](./network/)
5. [storage](./storage/)