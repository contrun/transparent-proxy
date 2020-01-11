terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region = "us-east-2"

  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

resource "aws_key_pair" "terraform_tester" {
  key_name   = "testers_key"
  public_key = file("/home/e/.ssh/id_rsa.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-eoan-19.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "aio_proxy" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.aio_proxy.id]
  key_name        = aws_key_pair.terraform_tester.key_name
}

resource "aws_security_group" "aio_proxy" {
  name = "aio_proxy"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port = 0
  to_port   = 0
  protocol  = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_inbound_udp" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_alter_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.alter_http_port
  to_port     = local.alter_http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_alter_http_inbound_udp" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.alter_http_port
  to_port     = local.alter_http_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

locals {
  http_port       = 80
  alter_http_port = 80
  https_port      = 80
  any_port        = 0
  any_protocol    = "-1"
  tcp_protocol    = "tcp"
  udp_protocol    = "udp"
  all_ips         = ["0.0.0.0/0"]
}

output "image_id" {
  value = data.aws_ami.ubuntu.id
}
