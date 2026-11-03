#################################################
# UBUNTU AMI
#################################################

data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

#################################################
# EC2 Three-Tier APPLICATION SERVER
#################################################

resource "aws_instance" "auto_application_server" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  key_name = "docker-key"

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  #################################################
  # USER DATA - AUTOMATIC THREE TIER DEPLOYMENT
  #################################################

  user_data = <<-EOF
#!/bin/bash

set -euxo pipefail

exec > >(tee -a /var/log/application-deployment.log) 2>&1

echo "=========================================="
echo " AWS THREE TIER APPLICATION DEPLOYMENT"
echo "=========================================="

#################################################
# STEP 1: UPDATE UBUNTU
#################################################

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y

#################################################
# STEP 2: INSTALL REQUIRED PACKAGES
#################################################

apt-get install -y \
  curl \
  unzip \
  git \
  docker.io \
  python3 \
  python3-pip

#################################################
# STEP 3: INSTALL AWS CLI V2
#################################################

cd /tmp

curl -fsSL \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o awscliv2.zip

unzip -q -o awscliv2.zip

./aws/install

rm -rf aws awscliv2.zip

aws --version

#################################################
# STEP 4: START DOCKER
#################################################

systemctl enable docker
systemctl start docker

#################################################
# STEP 5: CREATE DOCKER NETWORK
#################################################

docker network inspect mynetwork >/dev/null 2>&1 || \
docker network create mynetwork

#################################################
# STEP 6: CREATE DOCKER VOLUME
#################################################

docker volume inspect pgdata >/dev/null 2>&1 || \
docker volume create pgdata

#################################################
# STEP 7: FETCH EC2 PUBLIC IP
#################################################

TOKEN=$(curl -fsS -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

PUBLIC_IP=$(curl -fsS \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/public-ipv4")

echo "EC2 Public IP: $PUBLIC_IP"

#################################################
# STEP 8: AWS ECR LOGIN
#################################################

AWS_REGION="ap-south-1"

ECR_REGISTRY="667173675235.dkr.ecr.ap-south-1.amazonaws.com"

aws sts get-caller-identity

aws ecr get-login-password \
  --region $AWS_REGION | \
docker login \
  --username AWS \
  --password-stdin $ECR_REGISTRY

#################################################
# STEP 9: PULL DOCKER IMAGES
#################################################

IMAGE_TAG="dev-b472e0204f1023fd71d4dcf03bbe17c12df3bf65"

echo "Pulling PostgreSQL image..."

docker pull $ECR_REGISTRY/my-devops-webapp-database:$IMAGE_TAG

echo "Pulling Backend image..."

docker pull $ECR_REGISTRY/my-devops-webapp-backend:$IMAGE_TAG

echo "Pulling Frontend image..."

docker pull $ECR_REGISTRY/my-devops-webapp-frontend:$IMAGE_TAG

#################################################
# STEP 10: RUN POSTGRESQL DATABASE
#################################################

docker rm -f my_postgres || true

docker run -d \
  --name my_postgres \
  --network mynetwork \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=12345 \
  -e POSTGRES_DB=mydatabase \
  -v pgdata:/var/lib/postgresql/data \
  --restart unless-stopped \
  $ECR_REGISTRY/my-devops-webapp-database:$IMAGE_TAG

#################################################
# STEP 11: WAIT FOR DATABASE
#################################################

echo "Waiting for PostgreSQL..."

for i in $(seq 1 30); do

  if docker exec my_postgres \
    pg_isready -U admin -d mydatabase; then
    echo "PostgreSQL is ready!"
    break
  fi

  if [ "$i" -eq 30 ]; then
    echo "PostgreSQL failed to start!"
    docker logs my_postgres
    exit 1
  fi

  sleep 5

done

#################################################
# STEP 12: RUN BACKEND
#################################################

docker rm -f my-python-container || true

docker run -d \
  --name my-python-container \
  --network mynetwork \
  --restart unless-stopped \
  -e DB_HOST=my_postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=mydatabase \
  -e DB_USERNAME=admin \
  -e DB_PASSWORD=12345 \
  -e DB_SSLMODE=disable \
  -e CORS_ORIGINS="*" \
  -p 5000:5000 \
  $ECR_REGISTRY/my-devops-webapp-backend:$IMAGE_TAG

#################################################
# STEP 13: RUN FRONTEND
#################################################

docker rm -f my-frontend-container || true

docker run -d \
  --name my-frontend-container \
  --network mynetwork \
  --restart unless-stopped \
  -e API_URL="http://$PUBLIC_IP:5000" \
  -p 3000:80 \
  $ECR_REGISTRY/my-devops-webapp-frontend:$IMAGE_TAG

#################################################
# STEP 14: VERIFY CONTAINERS
#################################################

echo "Checking running containers..."

docker ps

#################################################
# STEP 15: DISPLAY APPLICATION URL
#################################################

echo "=========================================="
echo " THREE TIER DEPLOYMENT COMPLETED"
echo "=========================================="

echo "Frontend: http://$PUBLIC_IP:3000"

echo "Backend: http://$PUBLIC_IP:5000"

echo "Database: PostgreSQL - Port 5432"

echo "=========================================="

EOF

  tags = {
    Name = "auto-application-server"
  }
}
