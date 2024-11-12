#--------------------------------------------------------------------------
# Provision Highly Availabe Web in any Region Default VPC
# Create:
#    - Security Group for Web Server and ALB
#    - Launch Template with Auto AMI Lookup
#    - Auto Scaling Group using 2 Availability Zones
#    - Application Load Balancer in 2 Availability Zones
#    - Application Load Balancer TargetGroup
#    - RDS instance with PostgreSQL provider
# Update to Web Servers will be via Green/Blue Deployment Strategy
# Made by Kirill Ryzhikh 7-november-2024
#--------------------------------------------------------------------------


terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
}

provider "postgresql" {
  host            = aws_db_instance.web_db.address
  port            = var.database_port
  database        = local.postgres_db_name
  username        = var.database_username
  password        = local.postgres_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = true
}

provider "aws" {
  region = var.region
}

#-------------------------------------------------------------
# autoscaling_config for launch blue-green zero-time instances
#-------------------------------------------------------------

resource "aws_launch_template" "web" {
  name                   = "webserver-HA"
  image_id               = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_traffic.id]
  user_data              = base64encode(templatefile("${path.module}/init/init.tpl", { db_name = local.postgres_db_name }))
  tags                   = var.default_tags
  depends_on             = [aws_db_instance.web_db]
}

resource "aws_autoscaling_group" "web" {
  name                = "webserver-HA-ASG-Ver-${aws_launch_template.web.latest_version}"
  min_size            = 2
  max_size            = 2
  min_elb_capacity    = 2
  health_check_type   = "ELB"
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  target_group_arns   = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  dynamic "tag" {
    for_each = {
      Name   = "webserver in ASG-v${aws_launch_template.web.latest_version}"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}


#--------------------------------------------------------------------------
# //autoscaling_config for launch blue-green zero-time instances
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# database name and password 
#--------------------------------------------------------------------------

resource "random_string" "rds_password" {
  length           = 12
  special          = true
  override_special = "!#$&"
  keepers = {
    kepeer1 = "developer"
  }
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "psql"
  description = "Master Password for RDS PostgreSQL"
  type        = "SecureString"
  value       = random_string.rds_password.result
}

resource "random_string" "database_name" {
  length  = 5
  special = false
  keepers = {
    kepeer1 = "developer"
  }
}

#-------------------------------------------------------------------------
# // database name and password
#-------------------------------------------------------------------------

#--------------------------------------------------------------------------
# database instance
#--------------------------------------------------------------------------

locals {
  postgres_db_name  = random_string.database_name.result
  postgres_password = data.aws_ssm_parameter.rds_password.value
}

resource "aws_db_instance" "web_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  port                   = var.database_port
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  identifier             = "psql"
  db_name                = local.postgres_db_name
  username               = var.database_username
  password               = local.postgres_password
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.web_traffic.id]
  skip_final_snapshot    = true
}

#--------------------------------------------------------------------------
# // database instance
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Available Zones setting
#--------------------------------------------------------------------------

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.working.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.working.names[1]
}

#--------------------------------------------------------------------------
# // Available Zones setting
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Load Balancer settings
#--------------------------------------------------------------------------

resource "aws_lb" "web" {
  name               = "webserver-HA-ALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_traffic.id]
  subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  tags               = merge(var.default_tags, { Name = "${var.default_tags["Name"]}_lb" })
}

resource "aws_lb_target_group" "web" {
  name                 = "webserver-HA-TG"
  vpc_id               = aws_default_vpc.default.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 10 # seconds
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

#--------------------------------------------------------------------------
# // Load Balancer settings
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Security Group settings for allow traffic
#--------------------------------------------------------------------------

resource "aws_security_group" "web_traffic" {
  name        = "web_traffic"
  description = "Allow traffic and all outbound traffic"
  tags        = var.default_tags
  dynamic "ingress" {
    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "web_traffic" {
  security_group_id = aws_security_group.web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#--------------------------------------------------------------------------
# // Security Group settings for allow traffic
#--------------------------------------------------------------------------

