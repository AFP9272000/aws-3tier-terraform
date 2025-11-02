#!/bin/bash
set -euxo pipefail

# Update system and install nginx on Amazon Linux 2023
dnf -y update
dnf -y install nginx

# Create a simple landing page.  Feel free to customise this HTML to
# provide more meaningful content for your web tier.
cat >/usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Addison | Terraform 3‑Tier App</title>
  <style>
    body{font-family:system-ui,Segoe UI,Arial; margin:40px; line-height:1.5}
    .card{max-width:680px; margin:auto; padding:24px; border-radius:16px;
    box-shadow:0 10px 30px rgba(0,0,0,.07)}
    h1{margin:0 0 8px}
    code{background:#f5f5f7; padding:2px 6px; border-radius:6px}
  </style>
</head>
<body>
  <div class="card">
    <h1>Deployed with Terraform</h1>
    <p>Hello from <strong>Addison</strong>!  This EC2 instance is part of a secure 3‑tier
    architecture deployed via <code>terraform apply</code>.</p>
    <p>The stack includes a VPC, public and private subnets, an internet
    gateway, NAT gateway, security groups, an EC2 instance running NGINX,
    a private RDS database and a CloudFront‑fronted static site on S3.</p>
  </div>
</body>
</html>
HTML

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Optionally install the psql client for connecting to RDS.  This does
# not expose the database publicly but allows you to test connectivity
# from within the instance if needed.
dnf -y install postgresql15