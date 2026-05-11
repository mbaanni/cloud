
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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



resource "aws_instance" "lmachina" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.inception_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_tls.id]
  key_name               = "taxis"
  tags = {
    Name = "ubuntu-22-terraform"
  }
  /*provisioner "remote-exec" {
    inline = ["echo 'waiting for ssh to be ready'"]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("taxis.pem")
      host = self.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, --private-key taxis.pem -u ubuntu playbooks/ansible.yml"
  }*/
}
