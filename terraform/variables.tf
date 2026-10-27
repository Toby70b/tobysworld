variable "region" {
  description = "The AWS region the bucket and supporting resources are created in. The distribution itself is global."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource via the provider's default_tags."
  type        = map(string)
}

variable "domain_name" {
  description = "Apex domain of the existing Route 53 hosted zone, without a trailing dot (e.g. example.co.uk). Looked up as a data source — this stack does not create the zone."
  type        = string
}

variable "subdomain" {
  description = "Subdomain the map is served from. The full name becomes <subdomain>.<domain_name>."
  type        = string
}

variable "github_subject_prefix" {
  description = <<-EOT
    The OIDC subject prefix the deploy workflow presents, without the trailing
    ":ref:...". This repo has immutable subject claims enabled, so it carries
    numeric owner and repo IDs rather than the readable name. Read it from:
      gh api repos/<owner>/<repo>/actions/oidc/customization/sub
  EOT
  type        = string
}

variable "default_root_object" {
  description = "Object CloudFront serves for a request to the root of the distribution. The page is not named index.html, so this must match the file in site/."
  type        = string
  default     = "cloud-architecture.html"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 is the cheapest and covers North America and Europe."
  type        = string
  default     = "PriceClass_100"
}
