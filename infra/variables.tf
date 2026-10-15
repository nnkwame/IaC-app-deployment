variable "vpc_cidr_block" {
  description = "CIDR_Block for VPC Configuration"
  type        = string
  default     = "10.1.0.0/16"
}

variable "student_name" {
  description = "Your name (lowercase, no spaces). Used to name the VPC and key pair so students don't clash in the shared AWS account."
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR block definition of the subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "subnet_cidr_priv" {
  description = "The CIDR block definition of the subnet"
  type        = string
  default     = "10.1.10.0/24"
}


variable "subnet_cidr_az2" {
  description = "The CIDR block definition of the subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "az_1" {
  description = "The availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "az_2" {
  description = "The availability zone 2 for the subnet"
  type        = string
  default     = "us-east-1b"
}

variable "ami_architecture" {
  description = "CPU architecture to filter the AMI on."
  type        = string
  default     = "x86_64"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "security_group_name" {
  description = "Name of the security group (also used for its Name tag)."
  type        = string
  default     = "allow_http_ssh"
}

variable "security_group_description" {
  description = "Description of the security group."
  type        = string
  default     = "Allow HTTP & SSH inbound traffic and all outbound traffic"
}

variable "allowed_cidr_ipv4" {
  description = "CIDR block allowed for inbound HTTP/SSH and outbound traffic."
  type        = string
  default     = "0.0.0.0/0"
}

variable "http_port" {
  description = "TCP port used for HTTP ingress."
  type        = number
  default     = 80
}

variable "http_port_voteapp" {
  description = "TCP port used for voteapp frontend."
  type        = number
  default     = 8080
}

variable "http_port_result" {
  description = "TCP port used for result frontend."
  type        = number
  default     = 8081
}



variable "https_port" {
  description = "TCP port used for HTTPS ingress."
  type        = number
  default     = 443
}

variable "ssh_port" {
  description = "TCP port used for SSH ingress."
  type        = number
  default     = 22
}

variable "ingress_protocol" {
  description = "IP protocol used for the HTTP and SSH ingress rules."
  type        = string
  default     = "tcp"
}

variable "egress_ip_protocol" {
  description = "IP protocol for the egress rule (-1 = all protocols)."
  type        = string
  default     = "-1"
}
