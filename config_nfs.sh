#!/bin/bash

microk8s kubectl apply -f - <sc-nfs.yaml
microk8s kubectl apply -f - <pvc-nfs.yaml
