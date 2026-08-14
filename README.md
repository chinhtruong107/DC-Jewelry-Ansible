# DC Jewelry K3s Bootstrap

This repository runs **on the Terraform-created Control Node**. It bootstraps
the K3s cluster; it does not deploy the DC Jewelry application or run Docker
Compose.

## What it does

1. Installs `kubectl` and Helm on the Control Node.
2. Installs one K3s server on **K3s Server** in public subnet 1.
3. Reads `/var/lib/rancher/k3s/server/node-token` only in memory.
4. Installs K3s agents and joins every private worker in private subnet 1.
5. Fetches `/etc/rancher/k3s/k3s.yaml` to the Control Node at
   `/home/ubuntu/.kube/config`, rewrites its API endpoint to the K3s Server
   private IP, and verifies `kubectl get nodes`.

The token is marked `no_log` and is never written to inventory, group vars, or
Git. K3s keeps its server-side kubeconfig protected; the downloaded Control
Node copy is restricted to mode `0600`.

## Terraform contract

Populate `inventory/production.ini` and `inventory/group_vars/all.yml` from
the Terraform outputs after `terraform apply`:

| Ansible value | Terraform value needed |
| --- | --- |
| `k3s_server_private_ip` | Private IP of K3s Server in public subnet 1 (`10.0.1.0/24`) |
| `k3s_server` host | The same K3s Server private IP |
| each `k3s_workers` host | Private IP of each worker in private subnet 1 (`10.0.10.0/24`) |
| SSH key | Terraform-created private key, copied to `/home/ubuntu/.ssh/dcjewelry-k3s.pem` on Control Node |

Terraform security groups must allow:

- Control Node -> K3s Server: TCP `22`, `6443`.
- Control Node -> private workers: TCP `22`.
- K3s Server <-> private workers: TCP `6443`, `10250`, UDP `8472`.

Do not open Kubernetes API port `6443` to the Internet. The K3s server is in a
public subnet for Traefik/public ingress; cluster control traffic stays on VPC
private IPs.

## Prerequisites on Control Node

- Ubuntu with Ansible installed.
- This repository cloned at `/home/ubuntu/dc-jewelry-ansible`.
- The Terraform SSH private key copied to
  `/home/ubuntu/.ssh/dcjewelry-k3s.pem` with `chmod 600`.
- Valid private addresses replacing all `REPLACE_*` values.
- Private workers have NAT egress (or an approved mirror) to download K3s.

## Bootstrap

```bash
cd /home/ubuntu/dc-jewelry-ansible
chmod +x scripts/bootstrap-k3s.sh
./scripts/bootstrap-k3s.sh
```

After completion, use the cluster from the Control Node:

```bash
export KUBECONFIG=/home/ubuntu/.kube/config
kubectl get nodes -o wide
helm version
```

To add a worker, add its private IP under `[k3s_workers]` and rerun the script.
Existing nodes are left in place; changing the K3s version, server address, or
K3s server flags requires an explicit upgrade plan.
