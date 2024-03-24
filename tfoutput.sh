#!/bin/bash
terraform output -raw key_pair > key_pair.pem && echo >> key_pair.pem
chmod 600 key_pair.pem
ssh-add key_pair.pem
aws eks update-kubeconfig --region us-east-1 --name "$(terraform output -raw cluster_name)" --kubeconfig ./kubeconfig
echo "Run: export KUBECONFIG=$(pwd)/kubeconfig"
echo "SSH to db: $(terraform output -raw ssh_mongo)"
echo "Get Load Balancer: kubectl get service -n tasky tasky-service-loadbalancer"
echo "Get wizexercise.txt content: kubectl exec -n tasky -it deploy/tasky -- cat /app/wizexercise.txt"
echo "Get tasky service account: kubectl get deploy -n tasky tasky -o=jsonpath='{.spec.template.spec.serviceAccount}'"
echo "Get tasky rolebinding: kubectl get clusterrolebinding tasky-cluster-admin -o yaml"
