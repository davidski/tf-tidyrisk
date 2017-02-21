

terragrunt = {
  # Configure Terragrunt to use DynamoDB for locking
  lock = {
    backend = "dynamodb"
    config {
      state_file_id = "evaluator"
      aws_region = "us-west-2"
    }
  }

  # Configure Terragrunt to automatically store tfstate files in an S3 bucket
  remote_state = {
    backend = "s3"
    config {
      encrypt = "true"
      bucket = "infrastructure-severski"
      key = "terraform/evaluator.tfstate"
      region = "us-west-2"
    }
  }
}