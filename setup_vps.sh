#!/bin/bash
# ============================================
# Hostinger VPS Setup Script
# Run this on your VPS as root
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Django App VPS Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Update system
echo -e "${YELLOW}[1/8] Updating system...${NC}"
apt update && apt upgrade -y

# Step 2: Install Docker
echo -e "${YELLOW}[2/8] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker installed successfully${NC}"
else
    echo -e "${GREEN}Docker already installed${NC}"
fi

# Step 3: Install Docker Compose
echo -e "${YELLOW}[3/8] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed successfully${NC}"
else
    echo -e "${GREEN}Docker Compose already installed${NC}"
fi

# Step 4: Create deploy user
echo -e "${YELLOW}[4/8] Creating deploy user...${NC}"
if ! id "deploy" &>/dev/null; then
    adduser --disabled-password --gecos "" deploy
    usermod -aG docker deploy
    usermod -aG sudo deploy
    
    # Setup SSH key for deploy user
    mkdir -p /home/deploy/.ssh
    cp /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys 2>/dev/null || true
    chown -R deploy:deploy /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    chmod 600 /home/deploy/.ssh/authorized_keys 2>/dev/null || true
    
    # Allow deploy user to use sudo without password
    echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
    chmod 440 /etc/sudoers.d/deploy
    
    echo -e "${GREEN}Deploy user created${NC}"
else
    echo -e "${GREEN}Deploy user already exists${NC}"
fi

# Step 5: Setup project directory
echo -e "${YELLOW}[5/8] Setting up project directory...${NC}"
mkdir -p /var/www/my-django-app
chown deploy:deploy /var/www/my-django-app

# Step 6: Clone repository
echo -e "${YELLOW}[6/8] Cloning repository...${NC}"
cd /var/www/my-django-app
if [ -d ".git" ]; then
    git pull origin main
else
    echo -e "${YELLOW}Please clone your repository manually:${NC}"
    echo "cd /var/www/my-django-app && git clone https://github.com/YOUR_USERNAME/my-django-app.git ."
fi

# Step 7: Create .env file
echo -e "${YELLOW}[7/8] Creating .env file...${NC}"
if [ ! -f ".env" ]; then
    # Generate secure keys
    DJANGO_SECRET=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())" 2>/dev/null || openssl rand -base64 48)
    DB_PASS=$(openssl rand -base64 24)
    
    cat > .env << EOF
# Django settings
DJANGO_SECRET_KEY=${DJANGO_SECRET}
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=145.223.79.115

# Database settings
DB_ENGINE=django.db.backends.postgresql
DB_NAME=myproject
DB_USER=postgres
DB_PASSWORD=${DB_PASS}
DB_HOST=db
DB_PORT=5432

# PostgreSQL
POSTGRES_DB=myproject
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${DB_PASS}
EOF
    
    chown deploy:deploy .env
    echo -e "${GREEN}.env file created with secure keys${NC}"
    echo -e "${YELLOW}Secret key: ${DJANGO_SECRET}${NC}"
else
    echo -e "${GREEN}.env file already exists${NC}"
fi

# Step 8: Install Nginx and Certbot (for SSL)
echo -e "${YELLOW}[8/8] Installing Nginx and Certbot...${NC}"
apt install -y nginx certbot python3-certbot-nginx
systemctl enable nginx

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Clone your repository if not done:"
echo "   cd /var/www/my-django-app && git clone https://github.com/YOUR_USERNAME/my-django-app.git ."
echo ""
echo "2. Edit .env file with your domain:"
echo "   nano /var/www/my-django-app/.env"
echo ""
echo "3. Start the application:"
echo "   cd /var/www/my-django-app && docker-compose up -d --build"
echo ""
echo "4. Run migrations:"
echo "   docker-compose exec web python manage.py migrate --noinput"
echo ""
echo "5. Create superuser:"
echo "   docker-compose exec web python manage.py createsuperuser"
echo ""
echo "6. Setup SSL (after pointing domain DNS to this server):"
echo "   certbot --nginx -d YOUR_DOMAIN.com"
echo ""