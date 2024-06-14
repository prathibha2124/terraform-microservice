resource "aws_ecr_repository" "my_ecr" {
  name = var.repository_name
}

output "repository_url" {
  value = aws_ecr_repository.my_ecr.repository_url
}

