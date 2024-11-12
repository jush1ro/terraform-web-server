# Provision Highly Availabe Web in AWS any Region Default VPC

### Setup variables in tfvars file and environment variable for you aws instance
```
AWS_ACCESS_KEY_ID=****
AWS_SECRET_ACCESS_KEY=****
AWS_DEFAULT_REGION=***

terraform init
terraform plan
terraform apply -var-file="env-dev.tfvars"
terraform destroy
```