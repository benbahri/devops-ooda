#!/usr/bin/env bash
# Cree le cluster Kubernetes local (kind) et le kubeconfig "interne" utilise par Jenkins.
set -euo pipefail
cd "$(dirname "$0")"
if ! kind get clusters | grep -qx devops; then
  kind create cluster --config kind-config.yaml
fi
# Jenkins est dans un container rattache au reseau docker "kind" : il doit viser l'adresse interne.
kind get kubeconfig --name devops --internal > jenkins/kubeconfig
echo "Cluster pret :" && kubectl --context kind-devops get nodes
