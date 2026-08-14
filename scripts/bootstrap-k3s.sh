#!/usr/bin/env bash
set -Eeuo pipefail

ANSIBLE_REPO_DIR="/home/ubuntu/dc-jewelry-ansible"
ANSIBLE_BRANCH="main"
PLAYBOOK_FILE="playbooks/site.yml"

[[ -d "${ANSIBLE_REPO_DIR}/.git" ]] || { echo "Missing ${ANSIBLE_REPO_DIR}" >&2; exit 1; }
cd "${ANSIBLE_REPO_DIR}"
git fetch origin "${ANSIBLE_BRANCH}"
git checkout "${ANSIBLE_BRANCH}"
git pull --ff-only origin "${ANSIBLE_BRANCH}"
ansible-inventory --graph
ansible k3s_cluster -m ansible.builtin.ping
ansible-playbook "${PLAYBOOK_FILE}" --syntax-check
ansible-playbook "${PLAYBOOK_FILE}"
