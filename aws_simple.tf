terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }

  backend "remote" {
    organization = "glyph"

    workspaces {
      name = "Example-Workspace"
    }
  }
}

variable "awsprops" {
  type = map(string)
  default = {
    region       = "us-west-2"
    vpc          = "vpc-0b719606d990b4aa0"
    subnet       = "subnet-0ba44227e2a329540"
    ami          = "ami-07dd19a7900a1f049"
    itype        = "t2.micro"
    publicip     = true
    keyname      = "ansible-testing"
    secgroupname = "IAC-Sec-Group"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_security_group" "sg-ansible-testing" {
  name        = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id      = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "ansible-testing" {
  ami                         = lookup(var.awsprops, "ami")
  subnet_id                   = lookup(var.awsprops, "subnet")
  instance_type               = lookup(var.awsprops, "itype")
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name                    = lookup(var.awsprops, "keyname")

  vpc_security_group_ids = [
    aws_security_group.sg-ansible-testing.id
  ]
  root_block_device {
    delete_on_termination = true
    iops                  = 150
    volume_size           = 30
    volume_type           = "gp2"
  }
  tags = {
    Name        = "devops_test"
    Environment = "DEV"
    OS          = "UBUNTU"
    Managed     = "IAC"
  }


  depends_on = [aws_security_group.sg-ansible-testing]
}

output "ec2instance" {
  value = aws_instance.ansible-testing.public_ip
}
