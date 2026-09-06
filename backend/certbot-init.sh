#!/bin/bash
set -e

DOMAIN=${1:-"your.domain.com"}
EMAIL=${2:-"admin@your.domain.com"}
CERT_DIR="./nginx/certs"
DOCKER_COMPOSE="docker-compose.prod.yml"

echo "🔐 Initializing Let's Encrypt certificate for $DOMAIN"

mkdir -p $CERT_DIR

# Start Nginx in background with temporary SSL to pass ACME challenge
docker-compose -f $DOCKER_COMPOSE up -d nginx

sleep 3

# Request certificate from Let's Encrypt using Docker
docker run --rm \
  -v "$CERT_DIR/etc/letsencrypt:/etc/letsencrypt" \
  -v "$(pwd)/nginx/www:/var/www/certbot" \
  -p 80:80 \
  certbot/certbot \
  certonly --standalone \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN"

echo "✅ Certificate obtained for $DOMAIN"
echo "📝 Add to your systemd service to auto-renew:"
echo "   certbot renew --webroot -w ./nginx/www --post-hook 'docker-compose -f $DOCKER_COMPOSE exec api systemctl restart api'"

# Create renewal hook script
mkdir -p ./nginx/renewal-hooks
cat > ./nginx/renewal-hooks/post-renewal.sh << 'EOF'
#!/bin/bash
docker-compose -f docker-compose.prod.yml restart nginx api
EOF
chmod +x ./nginx/renewal-hooks/post-renewal.sh

echo "📋 Certificate files at:"
ls -lah $CERT_DIR/live/$DOMAIN/

# Restart services with real SSL
docker-compose -f $DOCKER_COMPOSE restart
