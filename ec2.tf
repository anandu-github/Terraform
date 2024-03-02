terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Deploy a Virtual Machine on AWS: Use Terraform to provision an EC2 instance on Amazon Web Services. 
#You'll need to define the instance type, AMI, networking settings, and any other desired configurations.



resource "aws_instance" "my-ec2-instance" {
 # ami           = data.aws_ami.ubuntu.id
  ami           = "ami-0cd59ecaf368e5ccf"
  instance_type = "t2.micro"
  key_name   = "ubuntu"


  tags = {
    Name = "terraform-ec2"
  }
}
