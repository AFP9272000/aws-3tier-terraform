/*
 * Variable definitions for the 3‑tier architecture.
 *
 * Many variables have sensible defaults for a development environment.  For
 * production override these via a terraform.tfvars file or
 * environment variables (github secrets) (TF_VAR_*).  Sensitive values such as db_password
 * should never be committed to version control.  See terraform.tfvars.example
 * for an example of how to supply them.
 */

variable "project_name" {
  description = "Name prefix for tagging and resource naming"
  type        = string
  default     = "addison-3tier"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnets across availability zones"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Two private subnets across availability zones"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the web tier"
  type        = string
  default     = "t2.micro"
}

variable "ingress_http_cidr" {
  description = "CIDR range allowed to access HTTP on the web tier.  Use your /32 to restrict."
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_ssh" {
  description = "Whether to allow SSH access to the web EC2 instance.  Set to false in production."
  type        = bool
  default     = true
}

variable "ssh_ingress_cidr" {
  description = "Public IP in CIDR form (e.g. x.x.x.x/32) allowed to SSH into the web instance"
  type        = string
  default     = "0.0.0.0/32"
}

variable "key_name" {
  description = "Existing EC2 key pair name used for SSH access to the web instance"
  type        = string
  default     = null
}

variable "db_engine" {
  description = "Database engine (only postgres is tested)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_username" {
  description = "Username for the RDS instance"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Password for the RDS instance.  Set this via tfvars or environment variables."
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage in gigabytes for the RDS instance"
  type        = number
  default     = 20
}

variable "site_bucket_name" {
  description = "Globally‑unique S3 bucket name for the frontend content (e.g. addison-3tier-site)"
  type        = string
}

variable "log_bucket_name" {
  description = "Globally‑unique S3 bucket name for access logs (CloudFront and S3)"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "waf_rate_limit" {
  description = "Maximum number of requests per 5‑minute period per IP before rate limiting kicks in"
  type        = number
  default     = 2000
}

variable "enable_waf" {
  description = "Whether to provision and attach a WAF Web ACL to the CloudFront distribution"
  type        = bool
  default     = true
}