provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "test_sg" {
  name        = "test_sg"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (not recommended for production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"            # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test_server" {
  ami                    = "ami-0866a3c8686eaeeba"  # Ensure this AMI is valid for your region
  instance_type          = "t3.medium"
  key_name               = "raaji"                   # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.test_sg.id]

  tags = {
    Name = "Test Server"
  }
}

output "test_server_ip" {
  value = aws_instance.test_server.public_ip
}




