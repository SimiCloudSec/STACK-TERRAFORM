variable "environment_tag" {
  description = "Environment tag"
  default     = "Learn"
}

variable "region"{
  description = "The region Terraform deploys your instance"
  default     = "us-east-1"
}

variable "vpc_id"{
  default = "vpc-0ffbc2e00e12373e5"
}

variable "subnets" {
  type = list(string)
  default = [
    "subnet-036a2bcbf3c1dc87f",
    "subnet-0e54a7b9c296556cb",
  ]
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "ses_key.pub"
}

variable "ami_name" {
  default = "ami-stack-1"
}
