terraform {
  backend "s3" {
    bucket       = "terraform-state-arch-map-8318927"
    key          = "terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
