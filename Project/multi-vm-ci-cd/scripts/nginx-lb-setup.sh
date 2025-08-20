#!/bin/bash

# Update package index
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Create a configuration file for load balancing
cat <<EOL | sudo tee /etc/nginx/sites-available/load_balancer
upstream docker_servers {
    server 192.168.56.13:80;
    server 192.168.56.14:80;
}

server {
    listen 80;

    location / {
        proxy_pass http://docker_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

# Enable the load balancer configuration
sudo ln -s /etc/nginx/sites-available/load_balancer /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx to apply changes
sudo systemctl restart nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx