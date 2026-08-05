#!/usr/bin/env bash

set -Eeuo pipefail

ANSIBLE_REPO_DIR="/home/ubuntu/dc-jewelry-ansible"
ANSIBLE_BRANCH="main"
PLAYBOOK_FILE="playbooks/deploy.yml"

echo "========================================"
echo "Starting Jewelry deployment"
echo "Time: $(date)"
echo "========================================"

if [[ ! -d "${ANSIBLE_REPO_DIR}/.git" ]]; then
    echo "Ansible repository does not exist:"
    echo "${ANSIBLE_REPO_DIR}"
    exit 1
fi

cd "${ANSIBLE_REPO_DIR}"

echo "Updating Ansible repository..."
git fetch origin "${ANSIBLE_BRANCH}"
git checkout "${ANSIBLE_BRANCH}"
git pull --ff-only origin "${ANSIBLE_BRANCH}"

echo "Checking Ansible inventory..."
ansible jewelry_servers --list-hosts

echo "Testing SSH connection..."
ansible jewelry_servers -m ansible.builtin.ping

echo "Checking playbook syntax..."
ansible-playbook "${PLAYBOOK_FILE}" --syntax-check

echo "Running deployment playbook..."
ansible-playbook "${PLAYBOOK_FILE}"

echo "========================================"
echo "Jewelry deployment completed"
echo "Time: $(date)"
echo "========================================"
