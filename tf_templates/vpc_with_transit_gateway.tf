// Cloning Terraform src code to /tmp/terraform_src...
 code has been checked out.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  CreateTransitGateway = var.deploy_transit_gateway == "true"
}

variable application {
  description = "Tag for all resources"
  type = string
  default = "vpc-peering-simulation"
}

variable vpc1_cidr {
  description = "Please enter the IP range (CIDR notation) for this VPC"
  type = string
  default = "10.1.0.0/16"
}

variable vpc2_cidr {
  description = "Please enter the IP range (CIDR notation) for this VPC"
  type = string
  default = "10.2.0.0/16"
}

variable vpc1_subnet_cidr {
  description = "Please enter the IP range (CIDR notation) for the public subnet in the first Availability Zone"
  type = string
  default = "10.1.1.0/24"
}

variable vpc2_subnet_cidr {
  description = "Please enter the IP range (CIDR notation) for the public subnet in the first Availability Zone"
  type = string
  default = "10.2.1.0/24"
}

variable type_of_instance {
  description = "Specify the Instance Type."
  type = string
  default = "t2.micro"
}

variable ami_id {
  description = "The ID of the AMI."
  type = string
  default = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

variable key_pair_name {
  description = "The name of an existing Amazon EC2 key pair in this region to use to SSH into the Amazon EC2 instances."
  type = string
  default = "Win-Key"
}

variable security_group_suffix {
  description = "Please enter the Security Group Suffix Name"
  type = string
  default = "sg"
}

variable deploy_transit_gateway {
  description = "Set to 'true' to deploy a Bastion Host in the public subnet."
  type = string
  default = "true"
}

resource "aws_vpc" "my_vpc1" {
  cidr_block = var.vpc1_cidr
  tags = {
    Name = "My-First-VPC"
    Application = var.application
  }
}

resource "aws_subnet" "vpc1_subnet" {
  vpc_id = aws_vpc.my_vpc1.arn
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  cidr_block = var.vpc1_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "VPC1-Subnet"
    Application = var.application
  }
}

resource "aws_internet_gateway" "vpc1_igw" {
  tags = {
    Name = "VPC1-IGW-Internet"
    Application = var.application
  }
}

resource "aws_vpn_gateway_attachment" "vpc1_igw_attachment" {
  vpc_id = aws_vpc.my_vpc1.arn
}

resource "aws_route_table" "vpc1_route_table" {
  vpc_id = aws_vpc.my_vpc1.arn
  tags = {
    Name = "VPC1-RT"
    Application = var.application
  }
}

resource "aws_route" "vpc1_route_table_igw_attachement" {
  route_table_id = aws_route_table.vpc1_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpc1_igw.id
}

resource "aws_network_acl" "vpc1_nacl" {
  vpc_id = aws_vpc.my_vpc1.arn
  tags = {
    Name = "VCP1-NACL"
  }
}

resource "aws_network_acl" "vpc1_nacl_inbound_rule" {
  vpc_id = aws_network_acl.vpc1_nacl.id
  // CF Property(RuleNumber) = 99
  // CF Property(Protocol) = -1
  // CF Property(RuleAction) = "allow"
  // CF Property(CidrBlock) = "0.0.0.0/0"
}

resource "aws_network_acl" "vpc1_nacl_outbound_rule" {
  vpc_id = aws_network_acl.vpc1_nacl.id
  // CF Property(RuleNumber) = 100
  // CF Property(Protocol) = -1
  egress = true
  // CF Property(RuleAction) = "allow"
  // CF Property(CidrBlock) = "0.0.0.0/0"
}

resource "aws_network_acl_association" "vpc1_subnet_network_acl_association" {
  subnet_id = aws_subnet.vpc1_subnet.id
  network_acl_id = aws_network_acl.vpc1_nacl.id
}

resource "aws_route_table_association" "vpc1_subnet_route_table_association" {
  route_table_id = aws_route_table.vpc1_route_table.id
  subnet_id = aws_subnet.vpc1_subnet.id
}

resource "aws_security_group" "vpc1_security_group" {
  name = join("-", ["vpc1", var.security_group_suffix])
  description = "Allow HTTP/HTTPS inbound traffic"
  vpc_id = aws_vpc.my_vpc1.arn
  ingress = [
    {
      protocol = "tcp"
      from_port = 80
      to_port = 80
      cidr_blocks = "0.0.0.0/0"
    },
    {
      protocol = "tcp"
      from_port = 443
      to_port = 443
      cidr_blocks = "0.0.0.0/0"
    },
    {
      protocol = "tcp"
      from_port = 22
      to_port = 22
      cidr_blocks = "0.0.0.0/0"
    },
    {
      protocol = "icmp"
      from_port = -1
      to_port = -1
      cidr_blocks = var.vpc2_cidr
    }
  ]
  tags = {
    Name = "VPC1-Public-SG"
    Application = var.application
  }
}

resource "aws_instance" "my_vpc1_server" {
  subnet_id = aws_subnet.vpc1_subnet.id
  // CF Property(ImageId) = var.ami_id
  instance_type = var.type_of_instance
  key_name = var.key_pair_name
  vpc_security_group_ids = [
    aws_security_group.vpc1_security_group.arn
  ]
  user_data = base64encode("#!/bin/bash
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello this is VPC 1" > /var/www/html/index.html
")
  tags = {
    Name = "vpc1-server"
    Application = var.application
  }
}

resource "aws_vpc" "my_vpc2" {
  cidr_block = var.vpc2_cidr
  tags = {
    Name = "My-Second-VPC"
    Application = var.application
  }
}

resource "aws_subnet" "vpc2_subnet" {
  vpc_id = aws_vpc.my_vpc2.arn
  availability_zone = element(// Unable to resolve Fn::GetAZs with value: "" because local variable 'az_data' referenced before assignment, 0)
  cidr_block = var.vpc2_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "VPC2-Subnet"
    Application = var.application
  }
}

resource "aws_internet_gateway" "vpc2_igw" {
  tags = {
    Name = "VPC2-IGW-vpc2-Internet"
    Application = var.application
  }
}

resource "aws_vpn_gateway_attachment" "vpc2_igw_attachment" {
  vpc_id = aws_vpc.my_vpc2.arn
}

resource "aws_route_table" "vpc2_route_table" {
  vpc_id = aws_vpc.my_vpc2.arn
  tags = {
    Name = "VPC2-RT"
    Application = var.application
  }
}

resource "aws_route" "vpc2_route_table_igw_attachement" {
  route_table_id = aws_route_table.vpc2_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpc2_igw.id
}

resource "aws_network_acl_association" "vpc2_subnet_network_acl_association" {
  subnet_id = aws_subnet.vpc2_subnet.id
  network_acl_id = aws_network_acl.vpc2_nacl.id
}

resource "aws_route_table_association" "vpc2_subnet_route_table_association" {
  route_table_id = aws_route_table.vpc2_route_table.id
  subnet_id = aws_subnet.vpc2_subnet.id
}

resource "aws_network_acl" "vpc2_nacl" {
  vpc_id = aws_vpc.my_vpc2.arn
  tags = {
    Name = "VCP2-NACL"
  }
}

resource "aws_network_acl" "vpc2_nacl_inbound_rule" {
  vpc_id = aws_network_acl.vpc2_nacl.id
  // CF Property(RuleNumber) = 99
  // CF Property(Protocol) = -1
  // CF Property(RuleAction) = "allow"
  // CF Property(CidrBlock) = "0.0.0.0/0"
}

resource "aws_network_acl" "vpc2_nacl_outbound_rule" {
  vpc_id = aws_network_acl.vpc2_nacl.id
  // CF Property(RuleNumber) = 100
  // CF Property(Protocol) = -1
  egress = true
  // CF Property(RuleAction) = "allow"
  // CF Property(CidrBlock) = "0.0.0.0/0"
}

resource "aws_security_group" "vpc2_security_group" {
  name = join("-", ["vpc2", var.security_group_suffix])
  description = "Allow HTTP/HTTPS inbound traffic"
  vpc_id = aws_vpc.my_vpc2.arn
  ingress = [
    {
      protocol = "tcp"
      from_port = 80
      to_port = 80
      cidr_blocks = "0.0.0.0/0"
    },
    {
      protocol = "tcp"
      from_port = 443
      to_port = 443
      cidr_blocks = "0.0.0.0/0"
    },
    {
      protocol = "tcp"
      from_port = 22
      to_port = 22
      cidr_blocks = "0.0.0.0/0"
    },
    {
      protocol = "icmp"
      from_port = -1
      to_port = -1
      cidr_blocks = var.vpc1_cidr
    }
  ]
  tags = {
    Name = "VPC2-Public-SG"
    Application = var.application
  }
}

resource "aws_instance" "my_vpc2_server" {
  subnet_id = aws_subnet.vpc2_subnet.id
  // CF Property(ImageId) = var.ami_id
  instance_type = var.type_of_instance
  key_name = var.key_pair_name
  vpc_security_group_ids = [
    aws_security_group.vpc2_security_group.arn
  ]
  user_data = base64encode("#!/bin/bash
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello this is VPC 2" > /var/www/html/index.html
")
  tags = {
    Name = "vpc2-server"
    Application = var.application
  }
}

resource "aws_ec2_transit_gateway" "demo_transit_gateway" {
  count = local.CreateTransitGateway ? 1 : 0
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  vpn_ecmp_support = "enable"
  dns_support = "enable"
  tags = {
    Name = "My-TransitGateway-Demo1"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1_transit_gateway_attachment" {
  count = local.CreateTransitGateway ? 1 : 0
  subnet_ids = [
    aws_subnet.vpc1_subnet.id
  ]
  transit_gateway_id = aws_ec2_transit_gateway.demo_transit_gateway[0].arn
  vpc_id = aws_vpc.my_vpc1.arn
  tags = {
    Name = "TransitGateway-Attachment-VPC1"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2_transit_gateway_attachment" {
  count = local.CreateTransitGateway ? 1 : 0
  subnet_ids = [
    aws_subnet.vpc2_subnet.id
  ]
  transit_gateway_id = aws_ec2_transit_gateway.demo_transit_gateway[0].arn
  vpc_id = aws_vpc.my_vpc2.arn
  tags = {
    Name = "TransitGateway-Attachment-VPC"
  }
}

resource "aws_route" "vpc1_route_table_vpc_transit_attachement" {
  count = local.CreateTransitGateway ? 1 : 0
  route_table_id = aws_route_table.vpc1_route_table.id
  destination_cidr_block = var.vpc2_cidr
  transit_gateway_id = aws_ec2_transit_gateway.demo_transit_gateway[0].arn
}

resource "aws_route" "vpc2_route_table_vpc_transit_attachement" {
  count = local.CreateTransitGateway ? 1 : 0
  route_table_id = aws_route_table.vpc2_route_table.id
  destination_cidr_block = var.vpc1_cidr
  transit_gateway_id = aws_ec2_transit_gateway.demo_transit_gateway[0].arn
}

output "vpc1_id" {
  description = "VPC ID of the newly created VPC"
  value = aws_vpc.my_vpc1.arn
}

output "vpc2_id" {
  description = "VPC ID of the newly created VPC"
  value = aws_vpc.my_vpc2.arn
}
