# --------------------------
# AWS CREDENTIAL VARIABLES
# --------------------------
variable "SRC_ACCESS_KEY" {
  type = string
}

variable "SRC_SECRET_KEY" {
  type = string
}

variable "DST_ACCESS_KEY" {
  type = string
}

variable "DST_SECRET_KEY" {
  type = string
}

# --------------------------
# REGION CONFIGURATION
# --------------------------
variable "SRC_REGION" {
  type    = string
  default = "us-east-1"
}

variable "DST_REGION" {
  type    = string
  default = "us-west-2"
}

# --------------------------
# BUCKET NAMES
# --------------------------
variable "SRC_BUCKET" {
  type    = string
  default = "simi-tf-src-bucket-protected"
}

variable "DST_BUCKET" {
  type    = string
  default = "simi-tf-dst-bucket-protected"
}

# --------------------------
# FORCE DESTROY FLAG
# --------------------------
variable "FORCE_DESTROY" {
  type    = bool
  default = true
}
