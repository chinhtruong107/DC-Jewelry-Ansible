# DC Jewelry K3s Bootstrap

This repository runs **on the Terraform-created Control Node**. It bootstraps
the K3s cluster; it does not deploy the DC Jewelry application or run Docker
Compose.

## What it does

1. Installs `git`, `kubectl`, and Helm on the Control Node.
2. Clones or updates the public `DC-Jewelry-K3s-Platform` checkout at
   `/home/ubuntu/dc-jewelry-k3s-platform` for GitHub Actions CD.
3. Installs one K3s server on **K3s Server** in public subnet 1.
4. Reads `/var/lib/rancher/k3s/server/node-token` only in memory.
5. Installs K3s agents and joins every private worker in private subnet 1.
6. Fetches `/etc/rancher/k3s/k3s.yaml` to the Control Node at
   `/home/ubuntu/.kube/config`, rewrites its API endpoint to the K3s Server
   private IP, and verifies `kubectl get nodes` as user `ubuntu`.

The token is marked `no_log` and is never written to inventory, group vars, or
Git. K3s keeps its server-side kubeconfig protected; the downloaded Control
Node copy is restricted to mode `0600`.

## Continuous delivery

After bootstrap, the Control Node has a working copy of the public Platform
repository at `/home/ubuntu/dc-jewelry-k3s-platform`. GitHub Actions in the
`DCJewelry` application repository can SSH to the Control Node and run its
K3s deployment script from that checkout. The checkout and kubeconfig are
owned by `ubuntu`, so the CD command can run `kubectl` with
`/home/ubuntu/.kube/config` without root.

This repository does not deploy Docker Compose. Do not commit the kubeconfig,
SSH private keys, K3s tokens, or database secrets; provide those only through
the appropriate host or GitHub secret mechanism.

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
- The Platform checkout is managed by this playbook at
  `/home/ubuntu/dc-jewelry-k3s-platform`; GitHub Actions CD uses this local
  checkout after SSHing to the Control Node.
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
