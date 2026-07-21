# K3s New Node

Terraform and Ansible scripts to provision a new virtual machine on Proxmox and join it as a worker node to an existing k3s cluster.

## Purpose

This repository automates the process of scaling a k3s cluster by adding a new node:

1. **Terraform** provisions a new VM on Proxmox, cloning it from an existing cloud-init template.
2. **Ansible** installs k3s on the new VM in agent mode, joining it to the existing cluster's Control Plane.

## Repository structure

```
.
├── Terraform/
│   ├── main.tf         # Defines the VM resource, cloned from a template
│   ├── providers.tf    # Configures the Proxmox provider (bpg/proxmox)
│   └── variables.tf    # Input variables for the Terraform configuration
└── Ansible/
    └── join-k3s.yaml   # Playbook that installs k3s in agent mode
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed on your machine.
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed on your machine.
- Access to a Proxmox instance, with an API token (see [Getting a Proxmox API token](#getting-a-proxmox-api-token) below).
- An existing cloud-init template on Proxmox to clone the new VM from.
- Access to the k3s cluster's Control Plane, to retrieve the join token (see [Retrieving the join token](#retrieving-the-join-token) below).

## Getting a Proxmox API token

Log in to the Proxmox web UI, go to `Datacenter` > `Permissions` > `API Tokens` and click `Add`.
Now select the user the token will belong to and enter a `Token ID`, a name to identify the token's purpose.
Lastly, click `Add`.

> **Warning**
> The token secret is shown only once, right after creation. Copy it immediately and store it securely.

## Retrieving the join token

Execute this command on the cluster's Control Plane:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Copy the output and store it securely, since it is sensitive information.
You'll need it later to run the Ansible playbook.

## Usage

### 1. Provision the VM with Terraform

Move into the `Terraform` folder:

```bash
cd Terraform
```

Create a `terraform.tfvars` file with your actual values, check `variables.tf` for a full description of each variable:

```hcl
proxmox_api_url = "https://<PROXMOX_HOST>:8006/"
proxmox_api_token = "<USER>!<TOKEN_ID>=<TOKEN_SECRET>"
vm_mac_address = "<VM_MAC_ADDRESS>"
ssh_public_key = "<YOUR_PUBLIC_KEY>"
vm_hostname = "<VM_HOSTNAME>"
target_node = "<A_PROXMOX_CLUSTER_NODE>"
template_node = "<PROXMOX_NODE_HOSTING_THE_TEMPLATE>"
template_id = <TEMPLATE_VM_ID>
```

> **Note**
> `vm_cpu_cores` (default `2`) and `vm_memory` (default `2048` MB) are optional and can be omitted if the defaults are fine for your setup.

> **Warning**
> `terraform.tfvars` contains sensitive values (the Proxmox API token) and is already excluded via `.gitignore` — never commit it.

Initialize and apply the configuration:

```bash
terraform init
terraform apply
```

Terraform will show the planned changes and ask for confirmation before creating the VM.

> **Note**
> Even after the `Apply complete!` message, you probably won't be able to
> access the new virtual machine yet, and will get a `Connection refused`
> error when trying to connect via SSH. This happens because the machine
> is still initializing — wait a couple of minutes and try again.

### 2. Join the node with Ansible

Move into the `Ansible` folder:

```bash
cd ../Ansible
```

Create an `inventory.ini` file listing the new node:

```ini
[new_nodes]
vm1 ansible_host=<IP_ADDRESS_OF_THE_NEW_MACHINE> ansible_user=ubuntu ansible_ssh_private_key_file=<PATH_TO_YOUR_PRIVATE_KEY> ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

> **Note**
> - `ansible_user` must be `ubuntu`, since that's the user configured via
>   cloud-init in the Terraform step.
> - `ansible_ssh_private_key_file` must point to the private key matching
>   the public key passed as `ssh_public_key` in `terraform.tfvars`.
> - `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` skips SSH's
>   first-connection host verification, which is otherwise required for a
>   freshly created VM Ansible has never connected to. This slightly
>   lowers protection against man-in-the-middle attacks — acceptable on a
>   trusted internal network, but worth keeping in mind.

Run the playbook, passing the join token retrieved earlier and the
Control Plane's URL as extra variables:

```bash
ansible-playbook -i inventory.ini join-k3s.yaml \
  -e k3s_url="https://<MASTER_IP>:6443" \
  -e k3s_token="<TOKEN>"
```

The playbook checks whether k3s is already installed on the target host
before running the installation, so it's safe to run more than once.

### 3. Verify

On the Control Plane, run:

```bash
kubectl get nodes
```

You should be able to see the new node.
