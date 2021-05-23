#!/bin/bash
kubectl apply -f files/4ingress/1arcadia_deploy.yaml
kubectl apply -f files/4ingress/1arcadia_increase.yaml
./files/4ingress/ingress_install.sh
