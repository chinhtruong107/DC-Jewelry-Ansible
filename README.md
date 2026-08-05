# Ansible Jewelry Deployment

Ansible project for automatically deploying the Duc Chinh Jewelry website.

## Architecture

GitHub Actions connects to the Ansible Control Node.

The Control Node runs this Ansible project and deploys the application to the
separate Frontend and Backend EC2 instances created by `DCJewelry-Terraform`.
The Backend is private and connects to the private MySQL RDS instance. The
Frontend is public and proxies server-side API calls to the Backend private IP.

## Deployment flow

1. Code is pushed to the `main` branch of the Jewelry repository.
2. GitHub Actions runs the CI workflow.
3. After CI succeeds, GitHub Actions connects to the Control Node.
4. The Control Node updates this Ansible repository.
5. Ansible connects from the Control Node to Frontend and Backend over SSH.
6. Each target pulls the latest application source code.
7. Backend Compose starts only `backend`; Frontend Compose starts only `frontend`.
8. Laravel migrations run on Backend against private RDS.
9. Local and public health checks are performed.

## Target server

- Project directory: `/home/ubuntu/dcjewelry`
- Frontend port: `3002`
- Backend port: `8002`
- Public URL: `https://dcjewelry.duckdns.org`

## Terraform alignment

Terraform creates three EC2 instances: Frontend in a public subnet, Backend
in `private_subnet_2`, and the Control Node in a public subnet. Run Ansible
from the Control Node and replace the two placeholders in
`inventory/production.ini` with the Frontend and Backend private IPs. The SSH
private key is Terraform's `keypair/key` (matching `keypair/key.pub`). Copy it
to `/home/ubuntu/.ssh/key` on the Control Node and run
`chmod 600 /home/ubuntu/.ssh/key`.

The current Terraform outputs expose the Frontend public/private IP and the
Control Node public IP, but not the Backend private IP. Add a Backend private
IP output to Terraform or obtain it from the EC2/Terraform state before
populating the inventory.

## Manual deployment

Run on the Control Node:

```bash
cd /home/ubuntu/ansible-jewelry
./scripts/deploy.sh
