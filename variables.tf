variable "aws_region" {
  default = "us-west-2"
}

variable "aws_profile" {
  description = "Name of AWS profile to use for API access."
  default     = "default"
}

variable "project" {
  description = "Default value for project tag."
  default     = "evaluator"
}
