terraform {
  backend "s3" {
    bucket       = "rp-cloudship-tfstate-d448591d"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
