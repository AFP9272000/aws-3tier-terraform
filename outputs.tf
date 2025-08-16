output "web_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL for testing"
  value       = "http://${aws_instance.web.public_ip}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}
