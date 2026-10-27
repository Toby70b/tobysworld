terraform {
  # Same pattern as game-repository: S3 remote state with native locking.
  # Fill in the bucket name (and change the key if you'd rather not share a
  # bucket with the other stacks), then run `terraform init`.
  #
  # backend "s3" {
  #   bucket       = "terraform-state-<account-id>"
  #   key          = "architecture-map/terraform.tfstate"
  #   region       = "eu-west-2"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
