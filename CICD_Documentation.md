# CI/CD Pipeline Documentation
## Django Application - Automated Deployment

**Project:** Python-CICD-Umair  
**Author:** Umair Rao  
**Date:** September 4, 2026  
**Version:** 1.0  

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Prerequisites](#3-prerequisites)
4. [Repository Setup](#4-repository-setup)
5. [CI Pipeline (Continuous Integration)](#5-ci-pipeline)
6. [CD Pipeline (Continuous Deployment)](#6-cd-pipeline)
7. [Docker Configuration](#7-docker-configuration)
8. [Server Setup](#8-server-setup)
9. [Environment Variables](#9-environment-variables)
10. [Nginx Configuration](#10-nginx-configuration)
11. [Deployment Process Flow](#11-deployment-process-flow)
12. [Troubleshooting](#12-troubleshooting)
13. [Conclusion](#13-conclusion)

---

## 1. Project Overview

This project demonstrates a complete **CI/CD (Continuous Integration / Continuous Deployment)** pipeline for a Django web application. The pipeline automatically:

- **Tests** code changes when pushed to GitHub (CI)
- **Deploys** verified changes to a production server (CD)

### Tech Stack

| Technology | Purpose |
|------------|---------|
| Python 3.12 | Programming Language |
| Django 6.1 | Web Framework |
| Gunicorn 23.0.0 | Production WSGI Server |
| PostgreSQL 15 | Database |
| Nginx 1.25 | Reverse Proxy |
| Docker & Docker Compose | Containerization |
| GitHub Actions | CI/CD Automation |
| Hostinger VPS | Cloud Hosting |
| Ubuntu 22.04 | Server Operating System |

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────┐
│                   DEVELOPER                         │
│              (Local Machine)                         │
│                                                     │
│   Write Code → Git Commit → Git Push to GitHub      │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                GITHUB REPOSITORY                    │
│          helpdeskireg-umair/Python-CICD-Umair       │
│                                                     │
│  ┌──────────────────┐    ┌──────────────────────┐   │
│  │   CI Pipeline    │    │    CD Pipeline       │   │
│  │   (ci.yml)       │───▶│    (cd.yml)          │   │
│  │                  │    │                      │   │
│  │ • Install deps   │    │ • SSH to VPS         │   │
│  │ • Run tests      │    │ • Pull latest code   │   │
│  │ • Validate code  │    │ • Rebuild containers │   │
│  └──────────────────┘    │ • Run migrations     │   │
│                          └──────────┬───────────┘   │
└─────────────────────────────────────┼───────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────┐
│              HOSTINGER VPS SERVER                   │
│              IP: 145.223.79.115                     │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │           DOCKER CONTAINERS                 │    │
│  │                                             │    │
│  │  ┌─────────┐  ┌──────────┐  ┌──────────┐  │    │
│  │  │  NGINX  │  │  DJANGO  │  │ POSTGRES │  │    │
│  │  │ :8080   │─▶│  APP     │─▶│   DB     │  │    │
│  │  │         │  │  :8000   │  │  :5432   │  │    │
│  │  └─────────┘  └──────────┘  └──────────┘  │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
              http://145.223.79.115:8080
```

---

## 3. Prerequisites

### Local Machine
- Python 3.12+
- Git
- GitHub account
- Text editor (VS Code recommended)

### Server (Hostinger VPS)
- Ubuntu 22.04 LTS
- Root access
- Minimum 1GB RAM
- Docker & Docker Compose installed
- Nginx installed

### GitHub Account
- Repository created
- Personal Access Token (PAT) generated with `repo` scope

---

## 4. Repository Setup

### 4.1 Project Structure

```
Python-CICD-Umair/
├── .github/
│   └── workflows/
│       ├── ci.yml              # CI Pipeline configuration
│       └── cd.yml              # CD Pipeline configuration
├── hello/                      # Django app
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── tests.py                # Automated tests
│   ├── urls.py
│   └── views.py
├── myproject/                  # Django project settings
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py             # Production-ready settings
│   ├── urls.py
│   └── wsgi.py
├── nginx/
│   └── nginx.conf              # Nginx reverse proxy config
├── .env.example                # Environment variables template
├── .gitignore
├── Dockerfile                  # Docker image definition
├── docker-compose.yml          # Multi-container orchestration
├── manage.py
├── requirements.txt            # Python dependencies
├── deploy.sh                   # Server setup script
└── README.md
```

### 4.2 Clone Repository

```bash
git clone https://github.com/helpdeskireg-umair/Python-CICD-Umair.git
cd Python-CICD-Umair
```

---

## 5. CI Pipeline (Continuous Integration)

**File:** `.github/workflows/ci.yml`

### Purpose
Automatically runs tests every time code is pushed to GitHub to ensure changes don't break existing functionality.

### Configuration

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    name: Run Django tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests
        run: python manage.py test
```

### How It Works

| Step | Action |
|------|--------|
| 1 | Triggered on push to `main` branch or pull request |
| 2 | Checks out the latest code from repository |
| 3 | Sets up Python 3.12 environment |
| 4 | Installs all dependencies from `requirements.txt` |
| 5 | Runs Django test suite (`python manage.py test`) |

### Tests Defined

```python
# hello/tests.py
class HomePageTests(SimpleTestCase):
    def test_home_page_returns_200(self):
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)

    def test_home_page_contains_greeting(self):
        response = self.client.get(reverse("home"))
        self.assertContains(response, "Hello, Umair Rao!")
```

---

## 6. CD Pipeline (Continuous Deployment)

**File:** `.github/workflows/cd.yml`

### Purpose
Automatically deploys the application to the production server after code is pushed to GitHub.

### Configuration

```yaml
name: CD

on:
  push:
    branches: [main]

jobs:
  deploy:
    name: Deploy to Hostinger VPS
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to VPS
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USERNAME }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /var/www/my-django-app
            git pull origin main
            docker-compose down
            docker-compose build --no-cache
            docker-compose up -d
            docker-compose exec web python manage.py migrate --noinput
            docker-compose exec web python manage.py collectstatic --noinput
            docker-compose exec web python manage.py createsuperuser --noinput || true
```

### How It Works

| Step | Action |
|------|--------|
| 1 | Triggered on push to `main` branch |
| 2 | Checks out the latest code |
| 3 | Connects to VPS via SSH using stored secrets |
| 4 | Pulls latest code from GitHub |
| 5 | Stops existing Docker containers |
| 6 | Rebuilds Docker images with latest code |
| 7 | Starts containers in detached mode |
| 8 | Runs database migrations |
| 9 | Collects static files |
| 10 | Creates superuser (if not exists) |

### GitHub Secrets Required

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `VPS_HOST` | Server IP address | `145.223.79.115` |
| `VPS_USERNAME` | SSH username | `root` |
| `VPS_SSH_KEY` | SSH private key | Contents of `/root/.ssh/id_rsa` |

---

## 7. Docker Configuration

### 7.1 Dockerfile

```dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
```

### 7.2 Docker Compose

**File:** `docker-compose.yml`

```yaml
services:
  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
    env_file:
      - .env
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    env_file:
      - .env
    restart: unless-stopped

  nginx:
    image: nginx:1.25
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf
      - static_volume:/app/staticfiles
    ports:
      - "8080:80"
    depends_on:
      - web
    restart: unless-stopped

volumes:
  postgres_data:
  static_volume:
```

### 7.3 Services Architecture

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `web` | Custom (Django) | 8000 (internal) | Application server |
| `db` | postgres:15 | 5432 (internal) | Database server |
| `nginx` | nginx:1.25 | 8080 (external) | Reverse proxy & static files |

---

## 8. Server Setup

### 8.1 Hostinger VPS Specifications

| Property | Value |
|----------|-------|
| Provider | Hostinger |
| IP Address | 145.223.79.115 |
| OS | Ubuntu 22.04 LTS |
| SSH Port | 22 |
| Control Panel | CloudPanel |

### 8.2 Initial Server Setup Script

**File:** `setup_vps.sh`

The script performs:
1. System package updates
2. Docker installation
3. Docker Compose installation
4. Deploy user creation with sudo access
5. Project directory creation (`/var/www/my-django-app`)
6. Nginx and Certbot installation

### 8.3 Deployment Commands

```bash
# Clone repository
cd /var/www/my-django-app
git clone https://github.com/helpdeskireg-umair/Python-CICD-Umair.git .

# Create environment file
cat > .env << EOF
DJANGO_SECRET_KEY=<generated-secret>
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=145.223.79.115
DB_ENGINE=django.db.backends.postgresql
DB_NAME=myproject
DB_USER=postgres
DB_PASSWORD=<generated-password>
DB_HOST=db
DB_PORT=5432
POSTGRES_DB=myproject
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<same-as-db-password>
EOF

# Build and start containers
docker-compose up -d --build

# Run migrations
docker-compose exec web python manage.py migrate --noinput

# Collect static files
docker-compose exec web python manage.py collectstatic --noinput

# Create admin user
docker-compose exec web python manage.py createsuperuser
```

---

## 9. Environment Variables

**File:** `.env`

```bash
# Django Security
DJANGO_SECRET_KEY=<48-character-random-string>
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=145.223.79.115

# Database Connection
DB_ENGINE=django.db.backends.postgresql
DB_NAME=myproject
DB_USER=postgres
DB_PASSWORD=<24-character-random-string>
DB_HOST=db
DB_PORT=5432

# PostgreSQL Container
POSTGRES_DB=myproject
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<same-as-DB_PASSWORD>
```

### Settings Integration

```python
# myproject/settings.py
import os

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', '<fallback>')
DEBUG = os.environ.get('DJANGO_DEBUG', 'True').lower() in ('true', '1', 'yes')
ALLOWED_HOSTS = os.environ.get('DJANGO_ALLOWED_HOSTS', 'localhost').split(',')

DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.sqlite3'),
        'NAME': os.environ.get('DB_NAME', BASE_DIR / 'db.sqlite3'),
        'USER': os.environ.get('DB_USER', ''),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', ''),
        'PORT': os.environ.get('DB_PORT', ''),
    }
}
```

---

## 10. Nginx Configuration

**File:** `nginx/nginx.conf`

```nginx
upstream django {
    server web:8000;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 10M;

    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /app/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /app/media/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### Request Flow

```
Client Request (port 8080)
        │
        ▼
    ┌───────┐
    │ NGINX │
    └───┬───┘
        │
   ┌────┴────┐
   │         │
   ▼         ▼
/static/   /
(requests)  │
   │        ▼
   │   ┌────────┐
   │   │ DJANGO │
   │   │  APP   │
   │   └───┬────┘
   │       │
   │       ▼
   │   ┌────────┐
   │   │POSTGRES│
   │   │   DB   │
   │   └────────┘
   │
   ▼
staticfiles/
(volume)
```

---

## 11. Deployment Process Flow

### Complete CI/CD Workflow

```
Developer pushes code to GitHub
            │
            ▼
┌──── CI Pipeline (ci.yml) ────┐
│                               │
│  1. Checkout code             │
│  2. Setup Python 3.12         │
│  3. Install dependencies      │
│  4. Run Django tests          │
│                               │
│  Result: PASS / FAIL          │
└───────────────┬───────────────┘
                │
                ▼ (PASS)
┌──── CD Pipeline (cd.yml) ────┐
│                               │
│  1. Checkout code             │
│  2. SSH to VPS                │
│  3. Git pull latest code      │
│  4. Docker compose down       │
│  5. Docker build --no-cache   │
│  6. Docker compose up -d      │
│  7. Run migrations            │
│  8. Collect static files      │
│                               │
│  Result: DEPLOYED             │
└───────────────┬───────────────┘
                │
                ▼
    Live App Updated at:
    http://145.223.79.115:8080
```

---

## 12. Troubleshooting

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| `psycopg2 not found` | Missing PostgreSQL adapter | Add `psycopg2-binary` to `requirements.txt` |
| `DJANGO_SECRET_KEY empty` | Env variable not set | Regenerate with `openssl rand -base64 48` |
| `Address already in use` | Port 80/443 taken by CloudPanel | Use port 8080 instead |
| `500 Server Error` | DEBUG=False hides errors | Temporarily set `DJANGO_DEBUG=True` to debug |
| `ModuleNotFoundError` | Dependency missing | Add to `requirements.txt` and rebuild |
| `Container restarting` | Application crash | Check logs with `docker-compose logs web` |

### Useful Debug Commands

```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs web --tail=50
docker-compose logs nginx --tail=50

# Enter container shell
docker-compose exec web bash

# Run Django management commands
docker-compose exec web python manage.py shell
docker-compose exec web python manage.py showmigrations

# Check environment variables inside container
docker-compose exec web env | grep DJANGO

# Rebuild from scratch
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## 13. Conclusion

This CI/CD pipeline provides:

1. **Automated Testing** - Every code change is validated through automated tests
2. **Zero-Downtime Deployment** - Docker containers ensure smooth deployments
3. **Reproducible Environments** - Docker guarantees consistent behavior across development and production
4. **Version Control Integration** - GitHub serves as the single source of truth
5. **Infrastructure as Code** - All configuration is versioned and documented

### Key Benefits

- **Speed**: Code changes go from development to production in minutes
- **Reliability**: Automated testing catches bugs before deployment
- **Consistency**: Docker eliminates "works on my machine" problems
- **Traceability**: Every deployment is linked to a specific commit
- **Scalability**: Easy to add more services or environments

---

*Document prepared by Umair Rao - September 2026*
