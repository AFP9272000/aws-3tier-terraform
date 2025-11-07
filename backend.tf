terraform {
  backend "s3" {
    bucket         = "afp9272000-3tier-tfstate-1762256499.27404"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "afp9272000-3tier-state-lock"
    encrypt        = true
  }
}
