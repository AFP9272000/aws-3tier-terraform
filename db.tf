############################################
# Private networking (original blocks)
############################################

# Private subnets (2 AZs)
resource "aws_subnet" "private" {
  for_each = {
    az1 = {
      cidr = var.private_subnet_cidrs[0]
      az   = data.aws_availability_zones.available.names[0]
    }
    az2 = {
      cidr = var.private_subnet_cidrs[1]
      az   = data.aws_availability_zones.available.names[1]
    }
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = merge(local.tags, { Name = "${var.project_name}-private-${each.key}" })
}

# NAT (single-AZ to cut cost) + EIP
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${var.project_name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["az1"].id # put NAT in a public subnet
  tags          = merge(local.tags, { Name = "${var.project_name}-nat" })
  depends_on    = [aws_internet_gateway.igw]
}

# Private route table -> default to NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${var.project_name}-private-rt" })
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate private subnets with private RT
resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

############################################
# Database security + subnet group + RDS
############################################

# DB Security Group (no inline ingress; separate rule goes below)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "RDS PostgreSQL SG"
  vpc_id      = aws_vpc.main.id

  # Outbound allowed (for patching, DNS, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-db-sg" })
}

# Ingress from web/app SG as a separate resource
# This avoids the circular dependency on delete and fixes the "SG still destroying" issue.
resource "aws_security_group_rule" "db_ingress_from_web" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.web_sg.id
  description              = "Postgres from web/app"
}

# Subnet group for RDS (private only)
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = merge(local.tags, { Name = "${var.project_name}-db-subnets" })
}

# RDS instance (Postgres)
resource "aws_db_instance" "db" {
  identifier                 = "${var.project_name}-pg"
  engine                     = var.db_engine         # e.g., "postgres"
  engine_version             = var.db_engine_version # e.g., "16.3"
  instance_class             = var.db_instance_class # e.g., "db.t4g.micro"
  allocated_storage          = var.db_allocated_storage
  db_subnet_group_name       = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids     = [aws_security_group.db_sg.id]
  username                   = var.db_username
  password                   = var.db_password
  publicly_accessible        = false
  multi_az                   = false
  storage_encrypted          = true
  skip_final_snapshot        = true
  deletion_protection        = false
  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  tags = merge(local.tags, { Name = "${var.project_name}-db" })
}

output "db_endpoint" {
  value       = aws_db_instance.db.address
  description = "Private RDS endpoint (only reachable inside VPC)"
}

