# Tech Assessment

Welcome to the Tech Assessment! Follow the steps below to get started:

### Prerequisites

* [Install terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* [Configure AWS Credentials File](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
    * Permissions should include the AWS Managed AdministratorAccess policy

## Step 1: Apply Terraform Configuration
```bash
terraform apply
```
## Step 2: Generate commands to simplify assessment
```bash
./tfoutputs.sh
```
## Step 2: Destroy resources when complete
```bash
terraform destroy
```

