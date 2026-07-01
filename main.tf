
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
  tags = {
    Name = "terraform-igw"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "inception_subnet" {
  vpc_id                  = aws_vpc.inception_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
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

  ingress {
    from_port   = 80
    to_port     = 80
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

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "lmachina" {

  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  count = 3
  subnet_id              = aws_subnet.inception_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_tls.id]
  key_name               = var.key_name
  tags = {
    Name = "ubuntu-22-terraform"
  }

}

resource "local_file" "inventory" {
  filename = "${path.module}/ansible/host_vars/cloud-1.yaml"
  content = <<EOF
  ${join([for instance in aws_instance.lmachina: ansible_host: ${aws_instance.lmachina.public_ip} ansible_user: ${var.osuser} ansible_ssh_private_key_file: ${var.ssh_key_path}],"\n")}
EOF
}
