# Phase 1 variables
variable "project_name" {
  description = "Name prefix for tagging and resource naming"
  type        = string
  default     = "addison-3tier"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnets across AZs"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for web"
  type        = string
  default     = "t2.micro"
}

variable "ingress_http_cidr" {
  description = "CIDR allowed for HTTP (80). Use your /32 to restrict."
  type        = string
  default     = "0.0.0.0/0"
}

# tier 2
variable "private_subnet_cidrs" {
  description = "Two private subnets across AZs"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "16" # safe default; change or remove if region mismatch
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro" # use db.t3.micro if ARM not available
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  description = "DB password (set in terra)"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}
variable "site_bucket_name" {
  description = "Globally-unique S3 bucket name for the frontend (like addison-3tier)"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}
variable "enable_ssh" {
  description = "Allow SSH to EC2 from my IP"
  type        = bool
  default     = true
}

variable "ssh_ingress_cidr" {
  description = "public IP in CIDR form (x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/32"
}

variable "key_name" {
  description = "Existing EC2 key pair name to SSH"
  type        = string
  default     = null
}


