# default variables

variable "region" {
  description = "region where to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "instance type"
  type        = string
  default     = "t3.micro"
}

variable "allow_ports" {
  description = "list of allow tcp ports for security group"
  default     = ["80", "443", "8080", "22"]
}

variable "database_port" {
  description = "tcp port for postgresql database"
  default     = "5432"
}

variable "database_username" {
  description = "username for postgresql database"
  default     = "developer"
}

variable "monitoring" {
  description = "monitoring of instances"
  type        = bool
  default     = "false"
}

variable "default_tags" {
  description = "default list of tags for resources"
  type        = map(string)
  default = {
    Name        = "web_demo"
    Owner       = "developers"
    Project     = "demo_application"
    Environment = "development"
  }
}
