resource "aws_iam_role" "ec2_ecr_role" {
  name = "EC2-ECR-FullAccess-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role = aws_iam_role.ec2_ecr_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-ECR-FullAccess-Profile"
  role = aws_iam_role.ec2_ecr_role.name
}