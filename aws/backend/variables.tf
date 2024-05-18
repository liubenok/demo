variable "aws_region" {
  description = "AWS Region for the S3 and DynamoDB"
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket for holding Terraform state files. Must be globally unique."
  type        = string
  default     = "liubenok-terraform-states-backend-001"
}

variable "dynamodb_table" {
  description = "DynamoDB table for locking Terraform states"
  type        = string
  default     = "liubenok-terraform-states-lock"
}