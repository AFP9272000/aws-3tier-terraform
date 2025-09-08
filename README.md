# AWS 3-Tier Application with Terraform

This project provisions a secure 3-tier architecture on AWS using Terraform:

- **Frontend:** S3 (private) + CloudFront (public, OAC)
- **App Layer:** EC2 in public subnet (NGINX demo server)
- **Database:** RDS PostgreSQL in private subnets
- **Networking:** VPC, public & private subnets, IGW, NAT Gateway, route tables
- **Security:** Least privilege IAM, security-group-to-security-group rules, private DB (not internet accessible)

- **Security Highlights:** IAM least privilege, private RDS, security group rules, CloudFront OAC, logging.

To reproduce:  

terraform fmt
terraform init
terraform plan -out=tfplan
terraform apply

> **Certs:** AWS SAA (earned). Studying Security+.  
> **Purpose:** Show real-world AWS + Security practices in a portfolio-ready project.

---

## Architecture Diagram

```mermaid
flowchart LR
  Internet -- HTTPS --> CF[CloudFront CDN]
  CF -- OAC --> S3[(S3 Bucket - Private)]
  subgraph VPC[ VPC ]
    direction LR
    subgraph Public[Public Subnets]
      EC2[EC2 Web/App]
      IGW[Internet Gateway]
      NAT[NAT Gateway]
    end
    subgraph Private[Private Subnets]
      RDS[(RDS PostgreSQL)]
    end
  end
  Internet <--> IGW
  EC2 -- 5432/TCP --> RDS
  Private --> NAT --> Internet
