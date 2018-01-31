#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi

KUBECTL_VERSION="1.9.2"
HELM_VERSION="2.8.0"

export CHANGE_MINIKUBE_NONE_USER=true

printf "\nInstalling kubectl...\n\n"

# install kubectl
curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

printf "\nInstalling helm...\n\n"

# install Helm
HELM_FILENAME="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
curl -L http://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME} -o /tmp/${HELM_FILENAME}
tar -zxvf /tmp/${HELM_FILENAME} -C /tmp
mv /tmp/linux-amd64/helm /usr/local/bin/helm

printf "\nInstalling minikube...\n\n"

# install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mv minikube /usr/local/bin/

printf "\nStarting minikube...\n\n"

# start minikube
minikube start --vm-driver=none
minikube update-context

printf "\nWaiting for minikube to be ready...\n\n"

# JSON path for node status check
JSONPATH="{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}"

# block until minikube is ready
until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do
  sleep 1
done

# confirm cluster is good
kubectl cluster-info

printf "\nInitializing helm...\n\n"

# initialize Helm and wait for Tiller to be ready
helm init
kubectl rollout status -w deployment/tiller-deploy -n kube-system

# give Tiller another 20 seconds to finish initializing
sleep 20

# confirm Helm is good
helm version

printf "\nInstalling the chart with helm...\n\n"

# install the chart and wait for the replica set to be ready
helm install --wait --name mongo ./mongodb-replicaset

kubectl get po -n default

printf "\nRunning MongoDB connectivity tests...\n\n"

# run the tests
./mongodb-replicaset/test.sh
