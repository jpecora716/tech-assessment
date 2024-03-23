#!/bin/bash
terraform output -raw key_pair > key_pair.pem && echo >> key_pair.pem
chmod 600 key_pair.pem
ssh-add key_pair.pem
aws eks update-kubeconfig --region us-east-1 --name "$(terraform output -raw cluster_name)" --kubeconfig ./kubeconfig
echo "Run: export KUBECONFIG=$(pwd)/kubeconfig"
