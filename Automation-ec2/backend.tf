terraform {
  backend "s3" {
    bucket = "terraform-backend-bucket-1234"
    key    = "compute/Abhishek/docker-automation/terraform.tfstate"
    region = "ap-south-1"
  }
}
