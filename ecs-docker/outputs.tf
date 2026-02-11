# ============================================================
# outputs.tf - Useful Info After terraform apply
# ============================================================

output "ecr_repository_url" {
  description = "ECR repository URL - use this to tag and push your Docker image"
  value       = aws_ecr_repository.clixx.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.clixx.name
}

output "nlb_dns_name" {
  description = "NLB DNS name - use this to access your app in the browser"
  value       = aws_lb.clixx_nlb.dns_name
}

output "website_url" {
  description = "Your website URL via Route 53"
  value       = "http://${var.domain_name}"
}

output "push_commands" {
  description = "Commands to push your Docker image to ECR"
  value       = <<-EOT
    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    # Tag your image
    docker tag clixx-image:latest ${aws_ecr_repository.clixx.repository_url}:${var.docker_image_tag}

    # Push to ECR
    docker push ${aws_ecr_repository.clixx.repository_url}:${var.docker_image_tag}
  EOT
}
