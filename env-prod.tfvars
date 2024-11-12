# parameters for launch production

region            = "eu-central-1"
instance_type     = "t3.micro"
monitoring        = true
allow_ports       = ["80", "443", "8080"]
database_port     = "5432"
database_username = "developer"
default_tags = {
  Name        = "web_demo"
  Owner       = "customers"
  Project     = "demo_application"
  Environment = "production"
}
