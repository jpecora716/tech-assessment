resource "aws_iam_role" "custom_role" {
  name               = "CustomEC2S3Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name   = "EC2CustomPolicy"
  description = "Custom policy for EC2"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.custom_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_policy" "s3_policy" {
  name   = "S3CustomPolicy"
  description = "Custom policy for S3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = ["arn:aws:s3:::${aws_s3_bucket.mongodb_backup_bucket.bucket}/*","arn:aws:s3:::${aws_s3_bucket.mongodb_backup_bucket.bucket}/"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.custom_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "mongodb" {
  name       = "Mongodb"
  role       = aws_iam_role.custom_role.name
}

resource "aws_security_group" "mongo_sg" {
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Allow traffic only from within the VPC
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all traffic
  }
}

resource "aws_s3_bucket" "mongodb_backup_bucket" {
  bucket = "mongodb-backup-${random_pet.bucket_suffix.id}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "mongodb_backup_bucket" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "mongodb_backup_bucket" {
  bucket = aws_s3_bucket.mongodb_backup_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "mongodb_backup_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.mongodb_backup_bucket,
    aws_s3_bucket_public_access_block.mongodb_backup_bucket,
  ]

  bucket = aws_s3_bucket.mongodb_backup_bucket.id
  acl    = "public-read"
}

resource "random_pet" "bucket_suffix" {
  length  = 3
}

resource "random_pet" "mongodbpw" {
  length  = 3
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = "mongodb"
  create_private_key = true
}

resource "aws_instance" "mongo" {
  ami           = "ami-02d7fd1c2af6eead0" # Change to your desired AMI
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  private_ip    = "10.0.4.100"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]
  key_name = module.key_pair.key_pair_name 
  tags = {
    Name = "mongodb"
  }
  iam_instance_profile = aws_iam_instance_profile.mongodb.name

  user_data = <<-EOF
              #!/bin/bash
              sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo > /dev/null <<EOT
              [mongodb-org-7.0]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://pgp.mongodb.com/server-7.0.asc
              EOT
              
              sudo yum install -y mongodb-org
              sudo systemctl start mongod.service
              sleep 30 && mongosh admin --eval 'db.createUser({user: "admin", pwd: "${random_pet.mongodbpw.id}", roles: [{role: "root", db: "admin"}]})'
              sudo sed -i "s/#security:/security:\n  authorization: enabled/" /etc/mongod.conf
              sudo sed -i 's/bindIp: 127.0.0.1/bindIpAll: true/' /etc/mongod.conf
              sudo systemctl restart mongod.service

              sudo tee -a /etc/crontab <<< "*/15 * * * * root mongodump --uri mongodb://admin:${random_pet.mongodbpw.id}@10.0.4.100:27017 --out /tmp/mongodb_backup && aws s3 cp /tmp/mongodb_backup s3://${aws_s3_bucket.mongodb_backup_bucket.bucket}/ --recursive"
              EOF
}
