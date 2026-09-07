# CI/CD for Django using GitHub Actions and Docker on a VPS

## Prerequisites
- GitHub repo with your code
- VPS (Ubuntu) with SSH access
- Docker & Docker Compose

## 1. Push Code to GitHub
```bash
git init
git remote add origin https://<token>@github.com/username/repo.git
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

## 2. VPS Setup (first time only)
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sh
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Clone project & create `.env`:
```bash
sudo mkdir /var/www/my-django-app && cd /var/www/my-django-app
sudo git clone https://<token>@github.com/username/repo.git .
```
`.env` file:
```
DJANGO_SECRET_KEY=<your-secret-key>
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=<your-vps-ip>
DB_ENGINE=django.db.backends.postgresql
DB_NAME=myproject
DB_USER=postgres
DB_PASSWORD=<your-db-password>
DB_HOST=db
DB_PORT=5432
POSTGRES_DB=myproject
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<your-db-password>
```

Start the app:
```bash
docker-compose up -d --build
docker-compose exec web python manage.py migrate --noinput
docker-compose exec web python manage.py collectstatic --noinput
docker-compose exec web python manage.py createsuperuser
```

## 3. Docker Config Files

**`Dockerfile`:**
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN python manage.py collectstatic --noinput
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
```

**`docker-compose.yml`:**
```yaml
services:
  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
    env_file: .env
    depends_on: [db]
    restart: unless-stopped
  db:
    image: postgres:15
    env_file: .env
    restart: unless-stopped
  nginx:
    image: nginx:1.25
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf
      - static_volume:/app/staticfiles
    ports:
      - "8080:80"
    depends_on: [web]
    restart: unless-stopped
volumes:
  postgres_data:
  static_volume:
```
> Use port `8080` because CloudPanel occupies port `80`.

## 4. Set Up SSH Key
On VPS:
```bash
ssh-keygen -t ed25519 -C "github-deploy"
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/id_ed25519   # copy this private key
```

## 5. Create GitHub Actions Workflows

**`.github/workflows/ci.yml`** (runs tests):
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r requirements.txt
      - run: python manage.py test
```

**`.github/workflows/cd.yml`** (deploys to VPS):
```yaml
name: CD
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
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
```

**GitHub Secrets** (Settings → Secrets → Actions):

| Secret | Value |
|--------|-------|
| `VPS_HOST` | Your VPS IP |
| `VPS_USERNAME` | `root` |
| `VPS_SSH_KEY` | Your SSH private key |

## 6. How It Works
1. Push code to `main`
2. CI runs tests
3. If tests pass, CD deploys to VPS
4. App updates at `http://your-vps-ip:8080`