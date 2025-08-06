variable "env" {}
variable "private_subnet_ids" {}
variable "public_subnet_ids" {}
variable "desired_size" {}
variable "max_size" {}
variable "min_size" {}

variable "eks_version" {
  default = 1.33
}
variable "kms_arn" {}