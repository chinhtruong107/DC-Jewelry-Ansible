# Ansible Jewelry Deployment

Ansible project for automatically deploying the Duc Chinh Jewelry website.

## Architecture

GitHub Actions connects to the Ansible Control Node.

The Control Node runs this Ansible project and deploys the application to the Jewelry EC2 instance.

## Deployment flow

1. Code is pushed to the `main` branch of the Jewelry repository.
2. GitHub Actions runs the CI workflow.
3. After CI succeeds, GitHub Actions connects to the Control Node.
4. The Control Node updates this Ansible repository.
5. Ansible connects to the Jewelry EC2 server.
6. Ansible pulls the latest application source code.
7. Docker Compose rebuilds and restarts the containers.
8. Laravel migrations are executed.
9. Local and public health checks are performed.

## Target server

- Project directory: `/home/ubuntu/jewelry`
- Frontend port: `3002`
- Backend port: `8002`
- Public URL: `https://dcjewelry.duckdns.org`

## Manual deployment

Run on the Control Node:

```bash
cd /home/ubuntu/ansible-jewelry
./scripts/deploy.sh