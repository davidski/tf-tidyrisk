# Configure S3 for State and Locking
terraform {
  backend "s3" {
    encrypt    = "true"
    bucket     = "infrastructure-severski"
    key        = "terraform/evauluator.tfstate"
    region     = "us-west-2"
    lock_table = "terraform_locks"
  }
}
