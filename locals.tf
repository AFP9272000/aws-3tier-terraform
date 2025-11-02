/*
 * Local values used across modules.  Tags are centralised here so they can be
 * merged consistently onto every resource.  Additional component‑specific
 * tags (e.g. Component = "frontend") are merged in individual files.
 */

locals {
  # Base tags applied to all resources.  Override or extend these via
  # `tags` variable in the future if needed.
  tags = {
    Project = var.project_name
    Managed = "terraform"
  }

  # Tags for the frontend resources.
  site_tags = merge(local.tags, { Component = "frontend" })

  # Tags for network resources (VPC, subnets, gateways).
  network_tags = merge(local.tags, { Component = "network" })

  # Tags for database resources.
  db_tags = merge(local.tags, { Component = "database" })

  # Tags for logging bucket
  log_tags = merge(local.tags, { Component = "log" })
}