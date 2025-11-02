```markdown
# Secure 3‑Tier AWS Architecture — Terraform

A compact, production‑minded Terraform configuration that provisions a secure three‑tier web stack on AWS. This repository demonstrates infrastructure-as-code best practices and DevSecOps controls: private origins, encryption, least‑privilege network rules, centralized tagging, logging, and a Web Application Firewall (WAF).

---

## What this repo does

- Builds a 3‑tier architecture:
  - Frontend: private S3 site bucket served through CloudFront (Origin Access Control).
  - Web tier: single EC2 instance running NGINX (user-data installs/configures).
  - Database tier: Amazon RDS PostgreSQL instance in private subnets.
- Implements security controls:
  - Private S3 origin + CloudFront OAC and restrictive bucket policy.
  - AWS WAF with managed rules and configurable rate limiting.
  - Encrypted storage for S3 and RDS, and versioning for buckets.
  - Narrowly scoped security groups and least‑privilege network flow.
- Operational hygiene:
  - Centralized tags (locals.tf) for consistent resource metadata.
  - Log bucket for CloudFront/S3 access logs with the appropriate write permissions.
  - Provider and Terraform version pinning and modular file layout for clarity.
  - Sensitive values are not committed — supply via tfvars or environment variables.

---

## Architecture diagram

Below is a mermaid diagram that visualises the deployed architecture: CloudFront with WAF in front of the private S3 origin, an EC2 web server in public subnets, a private RDS instance in private subnets, NAT for outbound access, and dedicated logging storage.

```mermaid
flowchart LR
  subgraph Edge
    CF[CloudFront Distribution]
    WAF[WAF Web ACL]
  end

  subgraph AWS_S3 [AWS S3]
    SiteBucket["Site S3 Bucket\n(private, versioned, SSE)"]
    LogBucket["Log S3 Bucket\n(versioned, SSE)"]
  end

  subgraph VPC [VPC]
    subgraph Public["Public Subnets"]
      EC2[EC2 (NGINX)\nsecurity-group: web-sg]
      IGW[Internet Gateway]
      NAT[NAT Gateway]
    end

    subgraph Private["Private Subnets"]
      RDS[RDS (Postgres)\nsecurity-group: db-sg]
      DBSubnetGroup[(DB Subnet Group)]
    end
  end

  CF -->|requests over HTTPS| SiteBucket
  CF -.->|access logs| LogBucket
  CF -->|protected by| WAF

  EC2 -->|serves app / proxy| CF
  EC2 -->|connects to| RDS
  EC2 -->|outbound via| NAT
  NAT --> IGW

  classDef svc fill:#f9f,stroke:#333,stroke-width:1px;
  class CF,WAF,SiteBucket,LogBucket,EC2,RDS,NAT svc
```

---

## Files overview

File | Purpose
---|---
provider.tf | Pin Terraform & AWS provider versions and set region via a variable.
variables.tf | Declares input variables, including: site_bucket_name, log_bucket_name, waf_rate_limit, enable_waf, etc.
locals.tf | Centralized tags and component tag maps.
main.tf | VPC, public subnets, route tables, security groups and the web EC2 instance (with unified tags).
db.tf | Private subnets, NAT gateway, DB subnet group, RDS (encrypted) and related security group.
frontend.tf | Site and log buckets (versioning/encryption), Origin Access Control, Response Headers Policy, CloudFront distribution and bucket policy.
waf.tf | WAF Web ACL with managed rule sets and rate limiting.
userdata.sh | EC2 user‑data: installs NGINX and deploys an informative landing page.
.gitignore | Keeps state, plans, secrets and env files out of version control.
terraform.tfvars.example | Example tfvars showing required bucket names and DB password patterns.

---

## Key features / security highlights

- Private origins: site bucket is not public; CloudFront OAC ensures objects are served only via the distribution.
- Encryption everywhere: SSE (S3) for buckets, KMS‑encrypted RDS storage.
- Immutable logs: CloudFront and S3 access logs delivered to a dedicated, versioned, encrypted log bucket.
- WAF protection: Managed rule sets (OWASP and AWS managed), plus a configurable rate limiting rule.
- Security headers: HSTS, X‑Frame‑Options, X‑Content‑Type‑Options, Referrer‑Policy, XSS protections via a Response Headers Policy.
- Least privilege networking: security groups restrict traffic to required ports and sources only.
- IaC hygiene: no secrets in repo; .gitignore includes terraform.tfstate, plan files, and .tfvars.

---

## Inputs (examples)

Create a `terraform.tfvars` (DO NOT commit) or set variables via environment. Example (see terraform.tfvars.example):

```hcl
site_bucket_name     = "my-unique-site-bucket-name"    # must be globally unique
log_bucket_name      = "my-unique-log-bucket-name"     # must be globally unique
db_password          = "YourComplexPasswordHere!"      # meet RDS complexity rules
```

Optional overrides:
- region (default: configured in variables.tf)
- instance_type
- enable_ssh (bool) and ssh_ingress_cidr
- waf_rate_limit (requests per 5 minutes)
- enable_waf (true/false)

---

## Outputs

After `terraform apply` the main outputs include:
- cloudfront_domain — CloudFront domain name to access the frontend
- web_url — Public URL for the EC2 web instance (if enabled)
- db_endpoint — RDS endpoint (private)

(Refer to outputs.tf in the repo for exact names.)

---

## Quick start

1. Clone the repo and cd into it.
2. Copy the example tfvars and update values:
   - cp terraform.tfvars.example terraform.tfvars
   - Edit terraform.tfvars — populate unique bucket names and db_password.
3. Initialize and apply:
   - terraform init
   - terraform plan
   - terraform apply

To destroy:
- terraform destroy

Notes:
- Bucket names are global and must be unique.
- For multi‑user teams enable a remote backend (S3 + DynamoDB locking).
- In production, consider a customer‑managed KMS key and enable final DB snapshots.

---

## Operational suggestions

- CI/CD: integrate terraform fmt, init, validate, plan and apply into your pipeline. Protect apply with approval gates.
- Monitoring: stream RDS and EC2 metrics to CloudWatch; create alarms for error rates, CPU, and unusual WAF blocks.
- Logging analysis: use Athena or CloudWatch Logs Insights to query CloudFront and S3 access logs.
- Secrets: use Secrets Manager or SSM Parameter Store (with encryption) for database credentials in automated pipelines.

---

## Future work / improvements

- Replace single EC2 web instance with an autoscaling group behind an ALB for resilience.
- Add ACM certificate and custom domain (CloudFront requires certificates in us‑east‑1).
- Expand WAF rulesets and custom rules informed by observed traffic patterns.
- Move Terraform state to S3 + DynamoDB for team workflows.

---

## License

MIT — see the LICENSE file.
