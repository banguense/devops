#!/bin/bash

mkdir ~/.kube
sudo microk8s config >~/.kube/config

#caso de algum erro nessa etapa, acesse: https://microk8s.io/docs/how-to-nfs
microk8s enable helm3
microk8s helm3 repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
microk8s helm3 repo update

microk8s helm3 install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --namespace default \
  --set kubeletDir=/var/snap/microk8s/common/var/lib/kubelet
