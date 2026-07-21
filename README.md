# CloudLab Talos on OCI

Terraform configuration for a two-node Talos Kubernetes cluster spanning two OCI tenancies in `ap-mumbai-1`.

## Architecture

- One `VM.Standard.A1.Flex` control plane in tenancy 1
- One `VM.Standard.A1.Flex` worker in tenancy 2
- 2 ARM OCPUs and 12 GB RAM per node
- 200 GB boot volume at 120 VPUs/GB per node
- Talos Linux 1.13.6 and dual-stack Kubernetes networking
- Talos-managed Flannel CNI and kube-proxy with dual-stack pod and service networks
- Official `siderolabs/tailscale` Talos system extension
- Private dual-stack node subnets joined by cross-tenancy LPG peering
- IPv4 internet egress through a NAT Gateway in each VCN
- IPv6 internet egress through an Internet Gateway with ingress prohibited on node subnets
- A public dual-stack Network Load Balancer for Kubernetes `6443` and Talos `50000`
- Daily incremental boot-volume backups retained for two days

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

The state contains Talos and Kubernetes private keys. Access to the state bucket must remain restricted to administrators.

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
The pinned Image Factory schematic is recorded in `infra/talos-schematic.yaml`. Terraform registers the control plane as `Triton` and the worker as `Scorpion` in the dedicated Tailscale tailnet.

## Variables

Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and replace the placeholder OCIDs. Export the shared API key without placing it in a variable file:

```bash
export TF_VAR_oci_private_key="$(<~/.oci/cloudlab_shared_api_key.pem)"
terraform -chdir=infra plan
```

## GitHub Actions

The workflow uses Terraform `1.15.8` and builds the Talos image archive on the runner. Pull requests run formatting, validation, and planning. Pushes to `main` and manual runs apply the exact saved plan.

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
TAILSCALE_OAUTH_CLIENT_SECRET
```

Repository variables:

```text
OCI_REGION
OCI_FINGERPRINT
OCI_REQUESTOR_GROUP_NAME
TAILSCALE_OAUTH_CLIENT_ID
TAILSCALE_TAILNET
```

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
