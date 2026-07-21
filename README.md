# CloudLab Talos on OCI

Terraform configuration for a two-node Talos Kubernetes cluster spanning two OCI tenancies in `ap-mumbai-1`.

## Architecture

- One `VM.Standard.A1.Flex` control plane in tenancy 1
- One `VM.Standard.A1.Flex` worker in tenancy 2
- 2 ARM OCPUs and 12 GB RAM per node
- 200 GB boot volume at 120 VPUs/GB per node
- Talos Linux 1.13.7, Kubernetes 1.36.2, and dual-stack networking
- Talos-managed Flannel CNI and kube-proxy with dual-stack pod and service networks
- Official `siderolabs/netbird` Talos system extension
- Private dual-stack node subnets joined by cross-tenancy LPG peering
- IPv4 internet egress through a NAT Gateway in each VCN
- IPv6 internet egress through an Internet Gateway with ingress prohibited on node subnets
- A public dual-stack Network Load Balancer for Kubernetes `6443` and Talos `50000`
- Daily incremental boot-volume backups retained for two days
- Terraform-managed Flux bootstrap reconciling `clusters/cloudlab`
- CA-signed kubelet serving certificates with automatic rotation and approval

The Talos nodes have no public IPv4 addresses. Their globally routable IPv6 addresses cannot receive internet-initiated traffic because the node subnets prohibit internet ingress and their security lists only admit traffic from the two VCNs. The public Talos API endpoint requires mutual TLS.

## State

Terraform state is stored in a private, versioned OCI Object Storage bucket. The native OCI backend provides state locking. The bucket must exist before Terraform can initialize.

Initialize the backend with the tenancy 1 API credentials:

```bash
terraform -chdir=infra init \
  -backend-config="tenancy_ocid=$TENANCY_1_OCID" \
  -backend-config="user_ocid=$TENANCY_1_USER_OCID" \
  -backend-config="fingerprint=$OCI_FINGERPRINT" \
  -backend-config="private_key_path=$HOME/.oci/cloudlab_shared_api_key.pem"
```

The state contains Talos and Kubernetes private keys. Credential inputs are ephemeral, but access to the state bucket must still remain restricted to administrators.

## Talos Image

OCI does not publish an official Talos image. Build the Oracle-compatible image archive before planning locally:

```bash
TALOS_VERSION="$(jq -r '.version' infra/talos-image.json)"
TALOS_SCHEMATIC_ID="$(jq -r '.schematic_id' infra/talos-image.json)"
mkdir -p infra/build
curl --fail --location \
  "https://factory.talos.dev/image/$TALOS_SCHEMATIC_ID/$TALOS_VERSION/oracle-arm64.qcow2" \
  --output infra/build/oracle-arm64.qcow2
cp infra/image_metadata.json infra/build/image_metadata.json
tar -C infra/build -czf infra/build/talos-oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json
```

Terraform uploads the archive to a private Object Storage bucket in each tenancy and imports it as a custom image.
The pinned Image Factory schematic is recorded in `infra/talos-schematic.yaml`. The version in `infra/talos-image.json` is the immutable bootstrap image version; changing it replaces the OCI instances. Runtime versions are tracked separately in `cluster-versions.json` and do not affect Terraform resources. Terraform registers the nodes as `Triton` and `Scorpion` in NetBird's `oci` group. That group provides HA routing for the Triton VPC, Scorpion VPC, pod, and service networks. Add every non-OCI device to `cloudlab-clients` to receive these routes and communicate directly with the OCI nodes. Assign networks advertised by those devices to `cloudlab-clients` so the OCI nodes can reach them. OCI network resources remain in `cloudlab-network-resources`, which prevents their routes from being advertised back to the OCI nodes.

## Variables

Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and replace the placeholder OCIDs. Export the shared API key without placing it in a variable file:

```bash
export TF_VAR_oci_private_key="$(<~/.oci/cloudlab_shared_api_key.pem)"
terraform -chdir=infra plan
```

## GitHub Actions

The workflow uses Terraform `1.15.8` and builds the Talos image archive on the runner. Pull requests run formatting, validation, and planning. Pushes to `main` and manual runs apply the exact saved plan.

Renovate proposes and automerges dependency updates, including separate Talos and Kubernetes runtime updates in `cluster-versions.json`. A runtime version update to `main` starts the **Cluster Upgrade** workflow automatically, and the workflow can also be run manually for retries. It validates that the requested release is no more than one minor version ahead, upgrades the control plane and worker sequentially, and checks Talos, Kubernetes node, and NetBird health after each change. Terraform apply, destroy, and cluster upgrade runs share a concurrency lock so they cannot modify the cluster simultaneously.

Repository secrets:

```text
OCI_PRIVATE_KEY
TENANCY_1_OCID
TENANCY_1_USER_OCID
TENANCY_1_COMPARTMENT_OCID
TENANCY_2_OCID
TENANCY_2_USER_OCID
TENANCY_2_COMPARTMENT_OCID
OCI_REQUESTOR_GROUP_OCID
NETBIRD_TOKEN
FLUX_GIT_SSH_PRIVATE_KEY
```

Repository variables:

```text
OCI_REGION
OCI_FINGERPRINT
OCI_REQUESTOR_GROUP_NAME
NETBIRD_MANAGEMENT_URL
```

## GitOps

Terraform bootstraps Flux into `clusters/cloudlab` using the Flux Terraform provider. The provider commits the controller and synchronization manifests to `main`, and Flux manages subsequent changes from Git.

The repository is split into reconciliation and workload layers:

```text
clusters/cloudlab/           # Cluster entrypoints and generated Flux bootstrap
infrastructure/controllers/  # Reusable platform components
infrastructure/cloudlab/     # Platform components enabled for CloudLab
apps/cloudlab/               # Applications enabled for CloudLab
```

The `apps` Flux Kustomization depends on `infrastructure`, so platform services become ready before applications are reconciled. Add reusable components under `infrastructure/controllers`, then include them from `infrastructure/cloudlab/kustomization.yaml`. Add application manifests or overlays under `apps/cloudlab`.

## Cluster Access

After a successful apply, retrieve the administrative configurations from remote state:

```bash
terraform -chdir=infra output -raw talosconfig > talosconfig
terraform -chdir=infra output -raw kubeconfig > kubeconfig
chmod 600 talosconfig kubeconfig
```

Create an application-consistent etcd snapshot before risky control-plane changes:

```bash
talosctl --talosconfig talosconfig -n 10.0.0.10 etcd snapshot etcd.snapshot
```

The scheduled OCI boot-volume backups provide machine-level recovery, while Talos etcd snapshots provide the preferred Kubernetes control-plane backup.
