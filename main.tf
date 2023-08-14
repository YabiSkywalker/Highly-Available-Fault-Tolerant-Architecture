# location of where the resources will be deployed 
provider "aws" {
  region = "vars.aws_region"
}
resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}
