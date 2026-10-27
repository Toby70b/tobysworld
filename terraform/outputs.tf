

output "site_url" {
  description = "The address the map is served from."
  value       = "https://${var.subdomain}.${var.domain_name}"
}

output "bucket_name" {
  description = "Bucket holding the page and its YAML — the target for `aws s3 sync`."
  value       = aws_s3_bucket.software_arch_map.id
}

output "distribution_id" {
  description = "Needed to invalidate the cache after an upload."
  value       = aws_cloudfront_distribution.s3_software_arch_distribution.id
}

output "invalidate_command" {
  description = "Run after uploading a change, or the edge keeps serving the old page."
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_software_arch_distribution.id} --paths '/*'"
}

output "github_deploy_role_arn" {
  description = "Set as the AWS_DEPLOY_ROLE_ARN repository variable in GitHub."
  value       = aws_iam_role.github_deploy.arn
}
