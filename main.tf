resource "aws_instance" "ec2" {
  ami           = var.ami
  instance_type = "t2.micro"
  key_name      = "mykeypair"

  tags = {
    Name = "Jenkins"
  }
}
