terraform {
  required_version = ">= 0.12, < 0.13"
}

variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "aws region where ec2 instance will be created"
}

variable "instances_count" {
  type        = number
  default     = 1
  description = "number of instances to be created"
}

variable "instance_tag" {
  type        = string
  default     = "aio_proxy"
  description = "tag of the ec2 instance to be created"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "type of the ec2 instance to be created"
}

variable "public_key" {
  type        = string
  default     = "/home/e/.ssh/id_rsa.pub"
  description = "path to the ssh public key with which you can access new created ec2 instance"
}

variable "public_key_name" {
  type        = string
  default     = "aio_proxy_key"
  description = "name of the key to be added to aws ec2"
}

variable "security_group_name" {
  type        = string
  default     = "aio_proxy"
  description = "name of the security group to be added to ec2 instance"
}

provider "aws" {
  region = var.aws_region
  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

resource "aws_key_pair" "terraform" {
  key_name   = var.public_key_name
  public_key = file(var.public_key)
}

# Obtain the ami of ubuntu 19.10
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
  count           = var.instances_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.aio_proxy.name]
  key_name        = aws_key_pair.terraform.key_name
  tags = {
    Name = var.instance_tag
  }
}

resource "aws_security_group" "aio_proxy" {
  name = var.security_group_name
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = 0
  to_port     = 0
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.udp_protocol
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

resource "aws_security_group_rule" "allow_http_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.udp_protocol
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

resource "aws_security_group_rule" "allow_https_udp_inbound" {
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

resource "aws_security_group_rule" "allow_alter_http_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.aio_proxy.id

  from_port   = local.alter_http_port
  to_port     = local.alter_http_port
  protocol    = local.udp_protocol
  cidr_blocks = local.all_ips
}

locals {
  ssh_port        = 22
  http_port       = 80
  alter_http_port = 8080
  https_port      = 443
  any_port        = 0
  any_protocol    = "-1"
  tcp_protocol    = "tcp"
  udp_protocol    = "udp"
  all_ips         = ["0.0.0.0/0"]
}

output "instance_ip" {
  value = aws_instance.aio_proxy.*.public_ip
}
