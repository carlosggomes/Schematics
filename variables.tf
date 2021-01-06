#TERRAFORM V0.12

# Define Variaveis

variable "ssh_key" {}
# variable "resource_group" {}

variable "name" {}

variable "zone1" {
  default = "eu-de-1"
}

variable "zone2" {
  default = "eu-de-2"
}

# variable "ssh_public_key" {
#   default = "~/.ssh/id_rsa.pub"
# }

variable "image" {
  default = "r010-ed3f775f-ad7e-4e37-ae62-7199b4988b00"
}

variable "profile" {
  default = "bx2-2x8"
}