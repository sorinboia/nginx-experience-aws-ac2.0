#!/bin/bash
echo "Starting Nginx Ingress Install"
rm -rf kubernetes-ingress
git clone https://github.com/nginxinc/kubernetes-ingress/
cd kubernetes-ingress/deployments
git checkout v1.11.1

kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac/rbac.yaml
kubectl apply -f rbac/ap-rbac.yaml
kubectl apply -f common/default-server-secret.yaml
kubectl apply -f common/nginx-config.yaml
kubectl apply -f common/ingress-class.yaml

kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_policies.yaml

kubectl apply -f common/crds/k8s.nginx.org_globalconfigurations.yaml
kubectl apply -f common/global-configuration.yaml

kubectl apply -f common/crds/appprotect.f5.com_aplogconfs.yaml
kubectl apply -f common/crds/appprotect.f5.com_appolicies.yaml
kubectl apply -f common/crds/appprotect.f5.com_apusersigs.yaml
kubectl apply -f service/loadbalancer-aws-elb.yaml

cd ../..

kubectl apply -f files/4ingress/nginx-ingress-install-edited.yaml
echo "Install finished"


