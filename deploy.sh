#!/bin/bash

# Deployment script for Hostinger VPS
# Run this script on your VPS server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting deployment...${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create project directory
echo -e "${YELLOW}Creating project directory...${NC}"
sudo mkdir -p /var/www/my-django-app
sudo chown $USER:$USER /var/www/my-django-app

# Clone repository
echo -e "${YELLOW}Cloning repository...${NC}"
cd /var/www/my-django-app
git clone https://github.com/YOUR_USERNAME/my-django-app.git .

# Create .env file
echo -e "${YELLOW}Creating .env file...${NC}"
cat > .env << EOF
# Django settings
DJANGO_SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=your_domain.com,www.your_domain.com

# Database settings
DB_ENGINE=django.db.backends.postgresql
DB_NAME=myproject
DB_USER=postgres
DB_PASSWORD=$(openssl rand -base64 32)
DB_HOST=db
DB_PORT=5432

# PostgreSQL
POSTGRES_DB=myproject
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -base64 32)
EOF

# Start services
echo -e "${YELLOW}Starting Docker services...${NC}"
docker-compose up -d

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
docker-compose exec web python manage.py migrate --noinput

# Collect static files
echo -e "${YELLOW}Collecting static files...${NC}"
docker-compose exec web python manage.py collectstatic --noinput

# Create superuser
echo -e "${YELLOW}Creating superuser...${NC}"
docker-compose exec web python manage.py createsuperuser --noinput || true

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Your app is now running at http://your_domain.com${NC}"