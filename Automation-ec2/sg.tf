################################################
# SECURITY GROUP
#################################################

resource "aws_security_group" "ec2_sg" {

  name = "docker-demo-sg"

  vpc_id = aws_vpc.main.id

  #################################################
  # SSH
  #################################################

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  #################################################
  # HTTP INBOUND
  #################################################

  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "Allow port 8080"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
  description = "Allow port 5432"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
  description = "Allow port 5000"
  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
  description = "Allow port 3000"
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  #################################################
  # OUTBOUND
  #################################################

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}