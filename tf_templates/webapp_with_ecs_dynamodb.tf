// Cloning Terraform src code to /tmp/terraform_src...
 code has been checked out.

data "aws_availability_zones" "available" {
  state = "available"
}

variable environment_name {
  description = "Environment name (e.g., dev, prod)."
  type = string
  default = "dev"
}

variable vpc1_cidr {
  description = "CIDR block for the first VPC."
  type = string
  default = "10.1.0.0/16"
}

variable vpc2_cidr {
  description = "CIDR block for the second VPC."
  type = string
  default = "10.2.0.0/16"
}

variable public_subnet1_cidr {
  type = string
  default = "10.1.1.0/24"
}

variable public_subnet2_cidr {
  type = string
  default = "10.1.2.0/24"
}

variable public_subnet3_cidr {
  type = string
  default = "10.1.3.0/24"
}

variable private_subnet1_cidr {
  type = string
  default = "10.1.101.0/24"
}

variable private_subnet2_cidr {
  type = string
  default = "10.1.102.0/24"
}

variable private_subnet3_cidr {
  type = string
  default = "10.1.103.0/24"
}

variable ecs_cluster_name {
  type = string
  default = "WebAppCluster"
}

resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc1_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment_name}-VPC1"
  }
}

resource "aws_vpc" "vpc2" {
  cidr_block = var.vpc2_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment_name}-VPC2"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.vpc1.arn
  cidr_block = var.public_subnet1_cidr
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.vpc1.arn
  cidr_block = var.public_subnet2_cidr
  availability_zone = element(// Unable to resolve Fn::GetAZs with value: "" because local variable 'az_data' referenced before assignment, 1)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet3" {
  vpc_id = aws_vpc.vpc1.arn
  cidr_block = var.public_subnet3_cidr
  availability_zone = element(// Unable to resolve Fn::GetAZs with value: "" because local variable 'az_data' referenced before assignment, 2)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet1" {
  vpc_id = aws_vpc.vpc1.arn
  cidr_block = var.private_subnet1_cidr
  availability_zone = element(// Unable to resolve Fn::GetAZs with value: "" because local variable 'az_data' referenced before assignment, 0)
}

resource "aws_subnet" "private_subnet2" {
  vpc_id = aws_vpc.vpc1.arn
  cidr_block = var.private_subnet2_cidr
  availability_zone = element(// Unable to resolve Fn::GetAZs with value: "" because local variable 'az_data' referenced before assignment, 1)
}

resource "aws_subnet" "private_subnet3" {
  vpc_id = aws_vpc.vpc1.arn
  cidr_block = var.private_subnet3_cidr
  availability_zone = element(// Unable to resolve Fn::GetAZs with value: "" because local variable 'az_data' referenced before assignment, 2)
}

resource "aws_ec2_transit_gateway" "transit_gateway" {
  description = "Transit Gateway connecting VPCs"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment_vpc1" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.arn
  vpc_id = aws_vpc.vpc1.arn
  subnet_ids = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id,
    aws_subnet.private_subnet3.id
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment_vpc2" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.arn
  vpc_id = aws_vpc.vpc2.arn
  subnet_ids = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id,
    aws_subnet.public_subnet3.id
  ]
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "web-app-task"
  cpu = "256"
  memory = "512"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = [
    {
      Name = "web-app"
      Image = "nginx"
      Memory = 512
      Cpu = 256
      PortMappings = [
        {
          ContainerPort = 80
        }
      ]
      Environment = [
        {
          Name = "DYNAMODB_TABLE"
          Value = aws_dynamodb_table.dynamo_db_table.arn
        }
      ]
    }
  ]
}

resource "aws_ecs_service" "ecs_service" {
  cluster = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  launch_type = "FARGATE"
  desired_count = 2
  network_configuration {
    // CF Property(AwsvpcConfiguration) = {
    //   Subnets = [
    //     aws_subnet.private_subnet1.id,
    //     aws_subnet.private_subnet2.id,
    //     aws_subnet.private_subnet3.id
    //   ]
    //   SecurityGroups = [
    //     aws_security_group.web_app_security_group.arn
    //   ]
    //   AssignPublicIp = "ENABLED"
    // }
  }
}

resource "aws_dynamodb_table" "dynamo_db_table" {
  name = "WebAppData"
  attribute = [
    {
      name = "id"
      type = "S"
    }
  ]
  // CF Property(KeySchema) = [
  //   {
  //     AttributeName = "id"
  //     KeyType = "HASH"
  //   }
  // ]
  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_security_group" "web_app_security_group" {
  vpc_id = aws_vpc.vpc1.arn
  description = "Allow inbound HTTP"
  ingress = [
    {
      protocol = "tcp"
      from_port = 80
      to_port = 80
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_iam_role" "ecs_task_execution_role" {
  assume_role_policy = {
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.arn
}

output "dynamo_db_table_name" {
  value = aws_dynamodb_table.dynamo_db_table.arn
}
