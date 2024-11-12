# template data and outputs for console

data "aws_availability_zones" "working" {}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["137112412989"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ssm_parameter" "rds_password" {
  name       = "psql"
  depends_on = [aws_ssm_parameter.rds_password]
}

data "aws_db_instance" "db_name" {
  depends_on = [aws_db_instance.web_db]
}

output "web_loadbalancer_url" {
  value = aws_lb.web.dns_name
}

output "rds_db_name" {
  value = data.aws_db_instance.db_name.db_name
}

output "rds_db_username" {
  value = var.database_username
}

output "rds_db_password" {
  value = "Check System Manager Parameter Store in AWS Console"
}


