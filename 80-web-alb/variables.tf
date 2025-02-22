variable "common_tags" {
  default = {
    project     = "expense"
    environment = "dev"
    terraform   = true
  }
}

variable "project_name" {
  default = "expense"
}

variable "environment" {
  default = "dev"
}

variable "zone_id" {
    default = "Z025468528XQ0B4FE5YQ9"
}

variable "domain_name" {
    default = "pradeepdevops.online"
}