locals {
  mime = {
    html  = "text/html"
    yaml  = "application/yaml"
    css   = "text/css"
    js    = "text/javascript"
    svg   = "image/svg+xml"
    png   = "image/png"
    jpg   = "image/jpeg"
    webp  = "image/webp"
    woff2 = "font/woff2"
  }
}

resource "aws_s3_object" "site" {
  for_each = fileset(var.site_dir, "**")

  bucket = aws_s3_bucket.software_arch_map.id
  key    = each.value
  source = "${var.site_dir}/${each.value}"
  etag   = filemd5("${var.site_dir}/${each.value}")

  content_type = lookup(local.mime, lower(regex("[^.]*$", each.value)), "application/octet-stream")

  cache_control = contains(["html", "yaml"], lower(regex("[^.]*$", each.value))) ? "public, max-age=60, s-maxage=300" : "public, max-age=31536000, immutable"
}