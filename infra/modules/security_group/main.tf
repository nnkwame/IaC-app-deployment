resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for i, rule in var.ingress_rules : i => rule
  }

  security_group_id = aws_security_group.this.id

  ip_protocol = each.value.ip_protocol
  from_port   = each.value.from_port
  to_port     = each.value.to_port

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  referenced_security_group_id = try(each.value.source_security_group_id, null)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for i, rule in var.egress_rules : i => rule
  }

  security_group_id = aws_security_group.this.id

  ip_protocol = each.value.ip_protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  referenced_security_group_id = try(each.value.source_security_group_id, null)
}
