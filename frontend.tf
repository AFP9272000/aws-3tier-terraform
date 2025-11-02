/*
 * Frontend tier: S3 static web bucket, logging bucket, CloudFront distribution
 * with secure defaults, and an origin access control (OAC) to keep the
 * origin private.  The distribution enforces HTTPS, adds common security
 * headers via a Response Headers Policy, emits access logs to a dedicated
 * bucket, and can optionally attach a WAF Web ACL.
 */

###############################################################
# Logging bucket for S3 and CloudFront
###############################################################

# Bucket that stores access logs.  A unique name must be supplied via
# var.log_bucket_name.  We allow ACLs to be used so that CloudFront can
# write logs into the bucket.  Public access is still restricted via
# restrict_public_buckets and block_public_policy.  Versioning and
# encryption are enabled to preserve and protect the logs.
resource "aws_s3_bucket" "log" {
  bucket        = var.log_bucket_name
  force_destroy = true # allow terraform destroy to remove the bucket and its contents
  tags          = local.log_tags
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket = aws_s3_bucket.log.id
  # Do not block public ACLs or ignore them so CloudFront can set the ACL on log objects
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    # Use ObjectWriter so CloudFront can write logs with its own ACL
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

###############################################################
# Site bucket for static assets
###############################################################

resource "aws_s3_bucket" "site" {
  bucket = var.site_bucket_name
  # When versioning is enabled, objects persist as previous versions.  The
  # force_destroy flag tells Terraform to empty the bucket (including all
  # versions) prior to deletion so that `terraform destroy` succeeds.
  force_destroy = true
  tags          = local.site_tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "site" {
  bucket        = aws_s3_bucket.site.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "s3-access-logs/"
}

###############################################################
# Upload static website content
###############################################################

# The index.html file and accompanying image are uploaded to the S3
# bucket at apply time.  Without these resources Terraform only
# provisions the infrastructure and leaves content deployment as a manual
# step.  Including them here ensures your CloudFront distribution
# immediately serves your landing page after apply.
resource "aws_s3_object" "site_index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  depends_on   = [aws_s3_bucket.site]
}

resource "aws_s3_object" "site_image" {
  bucket       = aws_s3_bucket.site.id
  key          = "DjzK_EnW4AEkCaP.jpg"
  source       = "${path.module}/DjzK_EnW4AEkCaP.jpg"
  content_type = "image/jpeg"
  depends_on   = [aws_s3_bucket.site]
}

###############################################################
# CloudFront origin access control and response headers
###############################################################

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  description                       = "Origin Access Control for S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Define a response headers policy to add security headers like HSTS,
# X-Frame-Options, X-Content-Type-Options, and XSS protection.  This
# improves the security posture of the site served from CloudFront.
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.project_name}-security-headers"
  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 63072000 # 2 years
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }
}

###############################################################
# CloudFront distribution
###############################################################

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  comment             = "${var.project_name} static site"
  default_root_object = var.default_root_object

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    # Attach the security headers policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Send logs to the log bucket
  logging_config {
    bucket          = aws_s3_bucket.log.bucket_domain_name
    include_cookies = false
    prefix          = "cf-logs/"
  }

  price_class = "PriceClass_100" # US/Canada/Europe

  tags = local.site_tags

  # Attach the WAF Web ACL.  Because this argument is optional, omitting it
  # entirely disables WAF.  If you do not wish to provision WAF set
  # `enable_waf = false` in your tfvars and comment out the line below.
  web_acl_id = aws_wafv2_web_acl.cf.arn
}

###############################################################
# Bucket policy to allow CloudFront to read from the S3 bucket
###############################################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "site_policy" {
  statement {
    sid       = "AllowCloudFrontRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
  depends_on = [
    aws_cloudfront_distribution.cdn,
    aws_s3_bucket_public_access_block.site,
    aws_s3_bucket_ownership_controls.site
  ]
}

###############################################################
# Outputs
###############################################################

output "cloudfront_domain" {
  description = "Public URL for the static site"
  value       = aws_cloudfront_distribution.cdn.domain_name
}