# https://registry.terraform.io/modules/cloudposse/config/aws/latest
module "awsconfig" {
  source = "cloudposse/config/aws"
  version     = "1.5.2"

  create_sns_topic = false
  create_iam_role  = true
  global_resource_collector_region = "us-east-1"
  s3_bucket_id = aws_s3_bucket.awsconfig_bucket.id
  s3_bucket_arn = aws_s3_bucket.awsconfig_bucket.arn
  force_destroy = true
}

# https://registry.terraform.io/modules/cloudposse/config/aws/latest/submodules/conformance-pack
module "devops_conformance_pack" {
  source = "cloudposse/config/aws//modules/conformance-pack"
  version     = "1.5.2"
  name = "DevOps Best Practices"
  conformance_pack="https://raw.githubusercontent.com/awslabs/aws-config-rules/master/aws-config-conformance-packs/Operational-Best-Practices-for-DevOps.yaml"
  depends_on = [module.awsconfig]
}

# Create an S3 bucket for AWS Config
resource "aws_s3_bucket" "awsconfig_bucket" {
  bucket = "awsconfig-${random_pet.bucket_suffix.id}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "awsconfig_bucket" {
  bucket = aws_s3_bucket.awsconfig_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "awsonfig_bucket" {
  bucket = aws_s3_bucket.awsconfig_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
