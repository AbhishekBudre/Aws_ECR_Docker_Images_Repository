# Docker Project — AWS EC2 Deployment Lab

## 1. Lab Objective

In this lab, students will install Docker and Docker Compose on an AWS EC2 Linux instance and deploy a full-stack application.

### Application Architecture

- **Frontend:** HTML, CSS, and JavaScript
- **Backend:** Python Flask API
- **Database:** PostgreSQL
- **Containerization:** Docker
- **Orchestration:** Docker Compose
- **Cloud platform:** AWS EC2

## 2. Project Structure

```text
Docker-Project/
├── docker-compose.yaml
├── .gitignore
├── backend/
│   ├── .env
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── database/
│   ├── .env
│   ├── create_table.sql
│   └── Dockerfile
└── frontend/
    ├── app.js
    ├── Dockerfile
    ├── index.html
    └── style.css
```

## 3. Prerequisites

Before starting the lab, students should have:

- An AWS account
- An EC2 instance running Amazon Linux 2023, Amazon Linux 2, or Ubuntu 22.04/24.04
- SSH access to the instance
- A project directory containing the application files
- Internet access from the EC2 instance to download packages and container images

### Recommended EC2 configuration

For this learning lab, use an instance with sufficient RAM and disk space for three containers and image builds. A 2-vCPU, 4-GiB instance is a reasonable starting point, though actual requirements depend on the application and image sizes.

## 4. Connect to the EC2 Instance

### Amazon Linux

The default username is usually `ec2-user`.

```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### Ubuntu

The default username is usually `ubuntu`.

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

Replace `your-key.pem` with your private key file and `YOUR_EC2_PUBLIC_IP` with the instance's public IP address.

On your local machine, protect the private key if necessary:

```bash
chmod 400 your-key.pem
```

## 5. Install Docker on Amazon Linux 2023

Run these commands after connecting to your instance.

### Step 1: Update packages

```bash
sudo dnf update -y
```

### Step 2: Install Docker

```bash
sudo dnf install docker -y
```

### Step 3: Start and enable Docker

```bash
sudo systemctl enable --now docker
```

### Step 4: Verify Docker

```bash
sudo systemctl status docker
sudo docker --version
```

### Step 5: Allow the EC2 user to run Docker

```bash
sudo usermod -aG docker ec2-user
```

Log out and reconnect to SSH so the new group membership takes effect.

```bash
exit
```

Reconnect using the SSH command from Section 4, then run:

```bash
docker ps
```

If you receive a permission error, reconnect again or continue using `sudo docker` until the group membership is active.

## 6. Install Docker on Amazon Linux 2

> Amazon Linux 2 and Amazon Linux 2023 use different package-management workflows.

### Step 1: Update packages

```bash
sudo yum update -y
```

### Step 2: Install Docker

```bash
sudo amazon-linux-extras install docker -y
```

### Step 3: Start and enable Docker

```bash
sudo systemctl enable --now docker
```

### Step 4: Add the EC2 user to the Docker group

```bash
sudo usermod -aG docker ec2-user
```

Log out and reconnect to SSH.

### Step 5: Verify Docker

```bash
docker --version
docker ps
```

If the `amazon-linux-extras` command is unavailable, confirm the instance's operating system version before continuing.

## 7. Install Docker on Ubuntu 22.04 or 24.04

These steps install Docker Engine and the Docker Compose plugin from Docker's official APT repository.

### Step 1: Update Ubuntu

```bash
sudo apt update
sudo apt upgrade -y
```

### Step 2: Install prerequisite packages

```bash
sudo apt install -y ca-certificates curl
```

### Step 3: Add Docker's official GPG key

```bash
sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Step 4: Add the Docker APT repository

```bash
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

### Step 5: Update package information

```bash
sudo apt update
```

### Step 6: Install Docker Engine and Docker Compose

```bash
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

### Step 7: Start and enable Docker

```bash
sudo systemctl enable --now docker
```

### Step 8: Verify the installation

```bash
sudo docker --version
sudo docker compose version
sudo systemctl status docker
```

### Step 9: Allow your Ubuntu user to run Docker

```bash
sudo usermod -aG docker "$USER"
```

Log out and reconnect to SSH so the group membership takes effect.

```bash
exit
```

Reconnect and verify:

```bash
docker ps
docker compose version
```

**Security note:** Membership in the `docker` group grants powerful privileges on the host, effectively root-level access. Only add trusted users.

## 8. Install or Verify Docker Compose on Amazon Linux

Docker Compose v2 is the plugin invoked as `docker compose`.

First, check whether it is already available:

```bash
docker compose version
```

If the command works, skip this section.

If the Compose plugin is missing, install the official Compose plugin binary for the EC2 instance's architecture.

### Step 1: Identify the CPU architecture

```bash
uname -m
```

Common results:

- `x86_64` — Intel/AMD instance
- `aarch64` — ARM-based Graviton instance

### Step 2: Install the Compose plugin

Run this command to select the matching official Linux binary:

```bash
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64)
    COMPOSE_ARCH="x86_64"
    ;;
  aarch64)
    COMPOSE_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

mkdir -p "$HOME/.docker/cli-plugins"

curl -fL \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${COMPOSE_ARCH}" \
  -o "$HOME/.docker/cli-plugins/docker-compose"

chmod +x "$HOME/.docker/cli-plugins/docker-compose"
```

### Step 3: Verify Docker Compose

```bash
docker compose version
```

This installs the plugin for the current user. If another user needs it, install the plugin for that user too. For production environments, use an approved version and a controlled update process.

## 9. Verify Docker Installation on Any Supported Linux Instance

Run:

```bash
docker --version
docker compose version
docker info
```

Test Docker by running the official test image:

```bash
docker run hello-world
```

If the test succeeds, Docker can download an image and run a container.

If permission is denied, try:

```bash
sudo docker run hello-world
```

Then check the Docker service:

```bash
sudo systemctl status docker
```

## 10. Prepare the Project

Upload or clone the `Docker-Project` directory onto the EC2 instance.

Navigate to the project directory:

```bash
cd Docker-Project
```

If you cloned a repository, use its actual directory name.

Verify the files:

```bash
ls -la
ls -la backend/
ls -la database/
ls -la frontend/
```

Confirm that the Compose file and the environment files exist.

## 11. Configure Environment Variables

### `database/.env`

```dotenv
POSTGRES_USER=admin
POSTGRES_PASSWORD=ReplaceWithAStrongPassword
POSTGRES_DB=mydatabase
```

### `backend/.env`

```dotenv
DB_HOST=postgres
DB_PORT=5432
DB_NAME=mydatabase
DB_USERNAME=admin
DB_PASSWORD=ReplaceWithAStrongPassword
DB_SSLMODE=disable
CORS_ORIGINS=http://YOUR_EC2_PUBLIC_IP:3000
```

Replace the example password with a strong password and use matching database credentials in both files.

Replace `YOUR_EC2_PUBLIC_IP` with your EC2 public IP address. If you use a domain name, configure the actual frontend origin instead.

Protect the environment files:

```bash
chmod 600 backend/.env database/.env
```

Ensure they are excluded from Git using the root `.gitignore`:

```gitignore
backend/.env
database/.env
frontend/.env
```

Note that `backend/.env` and `database/.env` are loaded separately by Compose using each service's `env_file` configuration.

## 12. Validate the Docker Compose Configuration

From the project root:

```bash
docker compose config
```

This command checks the Compose configuration and resolves supported environment-variable substitutions.

If validation fails, resolve the reported errors before building.

## 13. Build and Start the Application

```bash
docker compose up -d --build
```

This command builds the application images when required, creates the Compose network and named volume, and starts the containers in detached mode.

The PostgreSQL container should become healthy before Compose starts the backend because the configuration uses a PostgreSQL health check.

## 14. Check Container Status

```bash
docker compose ps
```

Include stopped containers:

```bash
docker compose ps --all
```

Check the running containers directly:

```bash
docker ps
```

## 15. View Container Logs

### PostgreSQL

```bash
docker compose logs -f postgres
```

### Backend

```bash
docker compose logs -f backend
```

### Frontend

```bash
docker compose logs -f frontend
```

Press `Ctrl+C` to stop following logs. This does not stop the containers.

To view the latest 100 lines:

```bash
docker compose logs --tail=100 postgres
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend
```

## 16. Test the Backend API

Run these commands from the EC2 instance:

```bash
curl -i http://localhost:5000/
curl -i http://localhost:5000/ready
curl -i http://localhost:5000/students
curl -i http://localhost:5000/items
```

The exact responses depend on the routes implemented in `backend/app.py`.

If a route returns `404`, confirm that the route exists in the application.

If the API reports that a relation or table does not exist, verify the database schema and initialization process.

## 17. Access the Frontend from Your Browser

Open:

```text
http://YOUR_EC2_PUBLIC_IP:3000
```

Replace `YOUR_EC2_PUBLIC_IP` with the instance's public IP address.

The frontend's JavaScript must call an API URL reachable from the user's browser. The internal Docker hostname `backend` is not normally resolvable from a browser outside the Docker network.

## 18. Configure the EC2 Security Group

For this lab, configure inbound rules according to the intended access:

| Port | Purpose | Recommended source |
|---|---|---|
| 22 | SSH | Your trusted public IP |
| 3000 | Frontend | Your IP or intended client range |
| 5000 | Direct backend API access | Only clients that require it |

Do not expose PostgreSQL port `5432` publicly.

For production deployments, prefer HTTPS through a reverse proxy or load balancer and avoid exposing the backend port directly unless required.

## 19. Useful Docker Compose Commands

### Rebuild and deploy

```bash
docker compose up -d --build
```

### Restart services

```bash
docker compose restart
```

### Stop services

```bash
docker compose stop
```

### Start stopped services

```bash
docker compose start
```

### Stop and remove containers and the Compose network

```bash
docker compose down
```

The named database volume is retained.

### Inspect resource usage

```bash
docker stats
```

### List images

```bash
docker images
```

### List volumes

```bash
docker volume ls
```

## 20. Troubleshooting

### Docker permission denied

```bash
sudo usermod -aG docker "$USER"
```

Log out and reconnect. Until permissions take effect, use `sudo docker ...`.

### Docker service is not running

```bash
sudo systemctl enable --now docker
sudo systemctl status docker
```

### Docker Compose command not found

```bash
docker compose version
```

If unavailable, follow Section 8 for Amazon Linux or Section 7 for Ubuntu.

### PostgreSQL authentication failed

Check that the backend credentials match the database credentials used when PostgreSQL was initialized.

Changing `POSTGRES_PASSWORD` in an environment file does not automatically reset the password of an existing PostgreSQL data directory.

### Database table does not exist

The SQL file mounted into `/docker-entrypoint-initdb.d/` runs only when PostgreSQL initializes an empty data directory. Updating the SQL file does not automatically apply changes to an existing database.

### Frontend cannot reach the backend

Check:

- The API URL configured in `frontend/app.js`
- The backend container logs
- CORS configuration
- EC2 security group rules
- Whether the backend is listening on the expected port

### Host port already in use

Check listening ports and container mappings:

```bash
docker compose ps
sudo ss -lntp
```

Resolve the port conflict before starting the services again.

## 21. Database Persistence Warning

PostgreSQL data is stored in the named volume `pgdata`.

Avoid running this command unless you intentionally want to delete the Compose-managed database volume and its data:

```bash
docker compose down -v
```

The `-v` option removes Compose-managed named volumes associated with this project.

## 22. Complete Deployment Workflow

After Docker and Docker Compose are installed, run the following commands from the project directory:

```bash
cd Docker-Project

# Validate configuration
docker compose config

# Build images and start services
docker compose up -d --build

# Check status
docker compose ps

# Check recent logs
docker compose logs --tail=100 postgres
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend

# Test the API
curl -i http://localhost:5000/ready
curl -i http://localhost:5000/students
curl -i http://localhost:5000/items
```

Finally, open the frontend in your browser:

```text
http://YOUR_EC2_PUBLIC_IP:3000
```

## 23. Official Documentation

- Docker Engine on Ubuntu: https://docs.docker.com/engine/install/ubuntu/
- Docker Compose: https://docs.docker.com/compose/
- AWS EC2 user guide: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/
- AWS guidance for installing Docker on Amazon Linux: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html
