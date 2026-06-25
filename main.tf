
provider "aws" {
  region = var.aws_region
}


resource "aws_vpc" "inception_vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.inception_vpc.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "inception_subnet" {
  vpc_id                  = aws_vpc.inception_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.inception_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.inception_subnet.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_security_group" "ssh_tls" {
  name        = "dev_sg"
  description = "dev_security_group"
  vpc_id      = aws_vpc.inception_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "lmachina" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.inception_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_tls.id]
  key_name               = "taxis"
  tags = {
    Name = "ubuntu-22-terraform"
  }

}

resource "local_file" "inventory" {
  filename = "${path.module}/ansible/host_vars/cloud-1.yaml"

  content = <<EOF
  ansible_host: ${aws_instance.lmachina.public_ip}
  ansible_user: ${var.osuser}
  ansible_ssh_private_key_file: ../keys/taxis.pem
  EOF
}
