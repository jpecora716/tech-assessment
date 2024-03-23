output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "kubeconfig" {
  value       = module.eks-kubeconfig.kubeconfig
  sensitive   = true
}

output "key_pair" {
  description = "Private key to connect to mongodeb"
  sensitive   = true
  value       = module.key_pair.private_key_openssh
}

output "ssh_mongo" {
  description = "Command to SSH to MongoDB Server"
  value       = "ssh ec2-user@${aws_instance.mongo.public_ip}"
} 
