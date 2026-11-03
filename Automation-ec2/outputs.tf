
output "public_ip" {

  value = aws_instance.auto_application_server.public_ip
}

output "ssh_command" {
    description = "SSH command to connect to the EC2 instance"

  value = "ssh -i docker-key.pem ubuntu@${aws_instance.auto_application_server.public_ip}"
}