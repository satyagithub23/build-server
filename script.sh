#!/bin/bash

set -o allexport
source .env
set +o allexport

export GIT_REPOSITORY_URL="$GIT_REPOSITORY_URL"
echo "$GIT_REPOSITORY_URL"

sudo mkdir -p /home/app/output

sudo git clone "$GIT_REPOSITORY_URL" /home/app/output

cd /home/app/output || exit


echo "Building the app image using Paketo Builder..."
pack build my-node-app --path . --builder paketobuildpacks/builder-jammy-base

if [ $? -eq 0 ]; then
    echo "Image built successfully."
else
    echo "Image build failed."
    exit 1
fi

echo "Running the Docker container..."
CONTAINER_ID=$(sudo docker run -d -p 0:3700 my-node-app)

if [ $? -ne 0 ]; then
    echo "Failed to start container."
    exit 1
fi

sleep 2


# Get the assigned host port
ASSIGNED_PORT=$(sudo docker inspect --format='{{(index (index .NetworkSettings.Ports "3700/tcp") 0).HostPort}}' "$CONTAINER_ID")

if [ -z "$ASSIGNED_PORT" ]; then
    echo "Failed to retrieve assigned port."
    exit 1
fi

echo "Container is running. Assigned port: $ASSIGNED_PORT"


# Configure NGINX to reverse proxy the container
echo "Setting up NGINX reverse proxy..."


# Create a new Nginx config
NGINX_CONFIG="/etc/nginx/sites-available/app-123.automateandlearn.fun"
BASE_DOMAIN="automateandlearn.fun"

sudo tee "$NGINX_CONFIG" > /dev/null <<EOL
server {

    server_name app-123.$BASE_DOMAIN;

    location / {
        proxy_pass http://localhost:$ASSIGNED_PORT; # Replace 3700 with dynamically assigned port
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}

EOL

sudo ln -s "$NGINX_CONFIG" /etc/nginx/sites-enabled/
sudo systemctl reload nginx

echo "Getting SSL for your domain..."

sudo certbot --nginx -d app-123.$BASE_DOMAIN

if [ $? -eq 0 ]; then
    echo "Successful..."
    echo "App is available at https://app-123.$BASE_DOMAIN"
else
    echo "Failed to get SSL for your domain. Please try again later!!!"
    exit 1
fi
# exec node app.js
