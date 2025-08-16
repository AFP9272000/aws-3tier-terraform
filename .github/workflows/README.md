# AWS 3-Tier App (Terraform) — Addison Pirlo

Infrastructure-as-Code project that provisions a secure 3-tier application on AWS:

- Frontend: S3 (private) + CloudFront (public, OAC)
- App: EC2 in public subnet (NGINX demo)
- Database: RDS PostgreSQL in private subnets
- Networking: VPC, public + private subnets, IGW, NAT, route tables
- Security: SG-to-SG only (EC2 → RDS), private DB, least privilege, no public S3

> Certs: AWS SAA (earned). Studying Security+.  
> Goals: Demonstrate production-style AWS + security skills end-to-end.

---

## Architecture

```mermaid
flowchart LR
  Internet -- HTTPS --> CF[CloudFront CDN]
  CF -- OAC (private access) --> S3[(S3 Bucket - private)]
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
