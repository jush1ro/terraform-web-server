# parameters for launch devel

region            = "eu-central-1"
instance_type     = "t3.micro"
monitoring        = false
allow_ports       = ["80", "443", "8080", "22"]
database_port     = "5432"
database_username = "developer"
default_tags = {
  Name        = "web_demo"
  Owner       = "developers"
  Project     = "demo_application"
  Environment = "development"
}
