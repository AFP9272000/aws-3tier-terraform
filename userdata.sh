#!/bin/bash
set -eux

# Amazon Linux 2023
dnf -y update
dnf -y install nginx

cat >/usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Addison | Terraform Web</title>
  <style>
    body{font-family:system-ui,Segoe UI,Arial; margin:40px; line-height:1.5}
    .card{max-width:680px; margin:auto; padding:24px; border-radius:16px; box-shadow:0 10px 30px rgba(0,0,0,.07)}
    h1{margin:0 0 8px}
    code{background:#f5f5f7; padding:2px 6px; border-radius:6px}
  </style>
</head>
<body>
  <div class="card">
    <h1>🚀 Deployed with Terraform</h1>
    <p>Hello from <strong>Addison</strong>! This EC2 instance was launched via <code>terraform apply</code>.</p>
    <p>Stack: VPC + public subnets + IGW + route tables + SG + EC2 + NGINX.</p>
  </div>
</body>
</html>
HTML

systemctl enable nginx
systemctl start nginx
dnf -y install postgresql15

