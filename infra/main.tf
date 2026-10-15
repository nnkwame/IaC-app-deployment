moved {
  from = aws_security_group.allow_http_ssh
  to   = module.app_sg.aws_security_group.this
}

#Create a new vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name      = "voteapp-proj-1-${var.student_name}"
    ManagedBy = "Terraform"
  }
}

locals {
  vpc_name = "voteapp-proj-1-${var.student_name}"
}

# Create a single subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.vpc_name}-public-subnet"
  }
}

# Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.vpc_name}-igw"
  }
}

# Create a route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.vpc_name}-public-az2-rt"
  }
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_az2.id
}

# aws_image
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }
}

data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*-server-*"]
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }
}



resource "aws_lb" "app" {
  name               = "${local.vpc_name}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [module.alb_sg.security_group_id]

  subnets = [aws_subnet.public.id, aws_subnet.public_az2.id]
}

resource "aws_lb_target_group" "voting" {
  name     = "${aws_lb.app.name}-vot-tg"
  port     = var.http_port_voteapp
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_target_group" "results" {
  name     = "${aws_lb.app.name}-res-tg"
  port     = var.http_port_result
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "voting" {
  target_group_arn = aws_lb_target_group.voting.arn
  target_id        = aws_instance.app.id
  port             = var.http_port_voteapp
}

resource "aws_lb_target_group_attachment" "results" {
  target_group_arn = aws_lb_target_group.results.arn
  target_id        = aws_instance.app.id
  port             = var.http_port_result
}

resource "aws_lb_listener" "voting" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.http_port_voteapp
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.voting.arn
  }
}

resource "aws_lb_listener" "results" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.http_port_result
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.results.arn
  }
}
# Single ec2 instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id

  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.app_sg.security_group_id, module.allow_ssh_app.security_group_id]

  tags = {
    Name = "${local.vpc_name}-app"
  }
}

resource "aws_instance" "jumphost" {
  ami           = data.aws_ami.ubuntu22.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.allow_ssh.security_group_id]

  tags = {
    Name = "${local.vpc_name}-jh"
  }
}


module "alb_sg" {
  source = "./modules/security_group"

  name        = "${var.security_group_name}-alb"
  description = "${var.security_group_description} - load-balancer"
  vpc_id      = aws_vpc.main.id

  ingress_rules = [
    {
      ip_protocol = var.ingress_protocol
      from_port   = var.http_port_voteapp
      to_port     = var.http_port_voteapp
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      ip_protocol = var.ingress_protocol
      from_port   = var.http_port_result
      to_port     = var.http_port_result
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]

  egress_rules = [
    {
      ip_protocol = var.egress_ip_protocol
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]
}

module "app_sg" {
  source = "./modules/security_group"

  name        = "${var.security_group_name}-app"
  description = var.security_group_description
  vpc_id      = aws_vpc.main.id

  ingress_rules = [
    {
      ip_protocol              = var.ingress_protocol
      from_port                = var.http_port_voteapp
      to_port                  = var.http_port_voteapp
      source_security_group_id = module.alb_sg.security_group_id
    },
    {
      ip_protocol              = var.ingress_protocol
      from_port                = var.http_port_result
      to_port                  = var.http_port_result
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]
}

module "allow_ssh" {
  source = "./modules/security_group"

  name        = "${var.security_group_name}-ssh"
  description = "${var.security_group_description} - ssh connections"
  vpc_id      = aws_vpc.main.id

  ingress_rules = [
    {
      ip_protocol = var.ingress_protocol
      from_port   = var.ssh_port
      to_port     = var.ssh_port
      cidr_ipv4   = var.allowed_cidr_ipv4
    }
  ]

  egress_rules = [
    {
      ip_protocol = var.egress_ip_protocol
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]
}

module "allow_ssh_app" {
  source = "./modules/security_group"

  name        = "${var.security_group_name}-ssh-app"
  description = "${var.security_group_description} - ssh connections for app grp"
  vpc_id      = aws_vpc.main.id

  ingress_rules = [
    {
      ip_protocol              = var.ingress_protocol
      from_port                = var.ssh_port
      to_port                  = var.ssh_port
      source_security_group_id = module.allow_ssh.security_group_id
    }
  ]

  egress_rules = [
    {
      ip_protocol = var.egress_ip_protocol
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]
}


# Generates a secure private key
resource "tls_private_key" "ed25519" {
  algorithm = "ED25519"
}

# Registers the public key with AWS
resource "aws_key_pair" "my_key" {
  key_name   = "${var.student_name}-ssh-key"
  public_key = tls_private_key.ed25519.public_key_openssh
}

# Saves the private key locally as a .pem file (in ansible folder)
resource "local_file" "private_key" {
  content         = tls_private_key.ed25519.private_key_openssh
  filename        = "${path.module}/../ansible/${var.student_name}-ssh-key.pem"
  file_permission = "0400" # Sets read-only permissions required by SSH
}

# Generate the Ansible inventory directly from the instance
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/hosts.ini"

  content = <<EOF
[voteapp]
app ansible_host=${aws_instance.app.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=./${var.student_name}-ssh-key.pem
EOF
}
