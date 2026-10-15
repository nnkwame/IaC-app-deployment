variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ingress_rules" {
  type = list(object({
    ip_protocol             = string
    from_port               = number
    to_port                 = number
    cidr_ipv4               = optional(string)
    source_security_group_id = optional(string)
  }))

  default = []
}

variable "egress_rules" {
  type = list(object({
    ip_protocol             = string
    from_port               = optional(number)
    to_port                 = optional(number)
    cidr_ipv4               = optional(string)
    source_security_group_id = optional(string)
  }))

  default = []
}

