resource "aws_instance" "ec2" {
  ami           = var.ami
  instance_type = "t2.micro"
  key_name      = "mykeypair"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y openjdk-17-jre
              java -version
              
              # Add Jenkins GPG key and repository
              curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
              /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
              https://pkg.jenkins.io/debian binary/ | sudo tee \
              /etc/apt/sources.list.d/jenkins.list > /dev/null
              
              # Update package list and install Jenkins
              sudo apt-get update -y
              sudo apt-get install -y jenkins
              
              # Start and enable Jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              EOF

  tags = {
    Name = "Jenkins"
  }
}
