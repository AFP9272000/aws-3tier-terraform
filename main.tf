/*
 * Core networking and compute resources for the 3‑tier architecture.  This file
 * defines the VPC, public subnets, routing, security groups and the EC2 web
 * server.  All resources are tagged via the locals defined in locals.tf.
 */

#
# VPC and public networking
#
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.network_tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.network_tags, { Name = "${var.project_name}-igw" })
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  for_each = {
    az1 = {
      cidr = var.public_subnet_cidrs[0]
      az   = data.aws_availability_zones.available.names[0]
    }
    az2 = {
      cidr = var.public_subnet_cidrs[1]
      az   = data.aws_availability_zones.available.names[1]
    }
  }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = merge(local.network_tags, { Name = "${var.project_name}-public-${each.key}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.network_tags, { Name = "${var.project_name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#
# Security group for the web tier
#

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP (and optionally SSH) to web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ingress_http_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Conditionally add an ingress rule for SSH if enabled.  Dynamic blocks are
  # used because Terraform does not allow conditional top‑level blocks.
  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []
    content {
      description = "SSH from allowed IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_ingress_cidr]
    }
  }

  tags = merge(local.network_tags, { Name = "${var.project_name}-web-sg" })
}

#
# Web tier (EC2 instance)
#

# Fetch the latest Amazon Linux 2023 AMI (x86_64).  For ARM architectures
# consider replacing the owners/filters accordingly.
data "aws_ami" "al2023" {
  owners      = ["137112412989"] # Amazon account for AL2023
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64*"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["az1"].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = file("${path.module}/userdata.sh")
  tags                        = merge(local.network_tags, { Name = "${var.project_name}-web" })
}

#
# Outputs
#

output "web_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL for the web server"
  value       = "http://${aws_instance.web.public_ip}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}