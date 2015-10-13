provider "aws" {
  access_key = ""
  secret_key = ""
  region = "us-west-2"
}

module "aws-dc" {
  source = "./terraform/aws"
  availability_zone = "us-west-2a"
  control_type = "t2.small"
  worker_type = "t2.small"
  ssh_username = "centos"

  # For use this ami you need find `centos` in AWS marketplace, and accept EULA
  source_ami = "ami-c7d092f7"
  control_count = 1
  worker_count = 3
}
