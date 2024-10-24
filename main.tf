terraform {
  required_providers {
    aws = {
      source ="hashicorp/aws"
      version = "5.72.1"
    }
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "AdministratorAccess-056984988198"
}

data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["801119661308"] # ID propriétaire pour les AMIs de Windows Server 2022 (AWS)

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "windows_server" {
  ami                         = data.aws_ami.windows_server.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.selected.id
  vpc_security_group_ids = [ aws_security_group.ws_ryan.id ]
  tags = {
    Name = "WindowsServer2022Instance"
  }
}

# Récupère un VPC spécifique en fonction de son tag (par exemple "Name")
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["ryan"]  # Remplacez par le nom de votre VPC
  }
}

data "aws_subnet" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]  # Filtre basé sur l'ID du VPC récupéré
  }

  filter {
    name   = "tag:Name"
    values = ["ryan"]
  }
}

resource "aws_security_group" "ws_ryan" {
  name        = "accept-RDP"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "RDP accept"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3389
    protocol    = "tcp"
    to_port     = 3389
  }

  egress {
    description = "internet accept"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"  # Signifie tous les protocoles
    to_port     = 0
  }

  tags = {
    Name = "accept-RDP"
  }
}
