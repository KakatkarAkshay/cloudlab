# CloudLab

CloudLab is an infrastructure-as-code and GitOps repository for running a Talos Linux Kubernetes cluster on Oracle Cloud Infrastructure.

It uses Terraform to:

- Provision the cloud networking, compute, storage, load balancing, and backup resources required by the cluster.
- Build and import a Talos image, configure the nodes, and bootstrap Kubernetes.
- Configure private, dual-stack cluster networking and secure administrative access.
- Bootstrap Flux so platform services and applications are continuously reconciled from this repository.

The GitOps configuration manages cluster capabilities including ingress, Gateway API support, DNS integration, authentication, metrics, secure tunneling, and kubelet certificate approval.

GitHub Actions and Renovate automate infrastructure validation and deployment, dependency updates, and Talos and Kubernetes upgrades.

## Reuse and Scope

The Terraform configuration in `infra/` is intended to be reusable. It can be used as a foundation for another OCI and Talos deployment by supplying the required Terraform inputs, GitHub Actions variables, and secrets.

The Flux and Kubernetes configuration in `clusters/`, `infrastructure/`, and `apps/` represents the desired state of my personal cluster. It intentionally contains deployment-specific choices such as domains, GitHub organization references, enabled applications, routing, and platform policy. These manifests are included as a working GitOps example rather than a generic distribution; reuse them by replacing or adapting that configuration for your own environment.

The Flux bootstrap configuration, including `clusters/cloudlab/flux-system/gotk-sync.yaml`, is tied to this repository by design.

## Repository Layout

```text
infra/                       # Terraform infrastructure and cluster bootstrap
clusters/                    # Flux cluster entrypoints
infrastructure/controllers/  # Reusable platform controllers
infrastructure/cloudlab/     # Platform components enabled for the cluster
apps/cloudlab/               # Applications enabled for the cluster
```
