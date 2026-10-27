variable "region" {
  description = "The AWS region the bucket and supporting resources are created in. The distribution itself is global."
  type        = string
  default     = "eu-west-2"
}

variable "tags" {
  description = "Tags applied to every resource via the provider's default_tags."
  type        = map(string)
  default = {
    project = "architecture-map"
  }
}

variable "domain_name" {
  description = "Apex domain of the existing Route 53 hosted zone, without a trailing dot (e.g. example.co.uk). Looked up as a data source — this stack does not create the zone."
  type        = string
}

variable "subdomain" {
  description = "Subdomain the map is served from. The full name becomes <subdomain>.<domain_name>."
  type        = string
  default     = "architecture"
}

variable "site_dir" {
  description = "Path to the directory whose contents are uploaded to the bucket, relative to this module."
  type        = string
  default     = "../site"
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
