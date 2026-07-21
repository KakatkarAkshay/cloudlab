# CloudLab

CloudLab is an infrastructure-as-code and GitOps repository for running a Talos Linux Kubernetes cluster on Oracle Cloud Infrastructure.

It uses Terraform to:

- Provision the cloud networking, compute, storage, load balancing, and backup resources required by the cluster.
- Build and import a Talos image, configure the nodes, and bootstrap Kubernetes.
- Configure private, dual-stack cluster networking and secure administrative access.
- Bootstrap Flux so platform services and applications are continuously reconciled from this repository.

The GitOps configuration manages cluster capabilities including ingress, Gateway API support, DNS integration, authentication, metrics, secure tunneling, and kubelet certificate approval.

GitHub Actions and Renovate automate infrastructure validation and deployment, dependency updates, and Talos and Kubernetes upgrades.

## Repository Layout

```text
infra/                       # Terraform infrastructure and cluster bootstrap
clusters/                    # Flux cluster entrypoints
infrastructure/controllers/  # Reusable platform controllers
infrastructure/cloudlab/     # Platform components enabled for the cluster
apps/cloudlab/               # Applications enabled for the cluster
```
