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

output "mongo" {
  description = "MongoDB IP"
  value       = aws_instance.mongo.public_ip
} 

output "mongo_backup" {
  description = "S3 REST Endpoint for MongoDB Backup bucket"
  value	      = "https://${aws_s3_bucket.mongodb.bucket}.s3.amazonaws.com/"
}
