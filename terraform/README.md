# Architecture map — hosting

Serves `site/` as a static site: a private S3 bucket behind a CloudFront
distribution, on a subdomain of the existing Route 53 zone.

The resource bodies aren't written — `main.tf` holds the build order and the
arguments worth getting right, in the order they need to exist.

## Layout

| File | State |
|---|---|
| `versions.tf` | done — Terraform and provider constraints |
| `providers.tf` | done — default region plus a `us_east_1` alias for ACM |
| `variables.tf` | done — domain, subdomain, site directory, price class |
| `backend.tf` | fill in the state bucket, then uncomment |
| `terraform.tfvars.example` | copy to `terraform.tfvars` and fill in |
| `main.tf` | **yours to write** — numbered build order in the comments |
| `outputs.tf` | uncomment as the resources land |

## Before the first apply

- The hosted zone must already exist; this stack looks it up with a data source
  rather than creating it. Only `var.domain_name` needs to match.
- The certificate has to live in **us-east-1** regardless of `var.region`, which
  is what the `aws.us_east_1` provider alias is for. CloudFront ignores
  certificates in any other region.
- DNS validation adds records to the zone, so the apply will sit for a few
  minutes on `aws_acm_certificate_validation` the first time.

## Then

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Publishing a change to the map

The page and its YAML are both in `site/`. If you upload them with
`aws_s3_object`, `terraform apply` covers it; if you sync them outside
Terraform:

```bash
aws s3 sync ../site s3://<bucket>/ --delete
aws cloudfront create-invalidation --distribution-id <id> --paths '/*'
```

The invalidation isn't optional — CloudFront will otherwise keep serving the
previous page until the cache expires.

## Two things to know about the page

- It is `cloud-architecture.html`, not `index.html`, so
  `default_root_object` is set from `var.default_root_object`. Rename the file
  and change that default if you'd rather use the convention.
- `site/architecture.yaml` and the YAML embedded at the bottom of the page are
  byte-identical — `scripts/sync_page.py` mirrors one into the other, and
  `scripts/check_architecture.py` fails if they drift. The page only fetches the standalone file once
  `data-yaml-src="architecture.yaml"` is set on its `<html>` tag — that's left
  off for now, so it renders from the embedded copy. Set it after the first
  apply and the map becomes editable by uploading the YAML alone.
