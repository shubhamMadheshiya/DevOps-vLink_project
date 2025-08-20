#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Docker installation on Ubuntu..."

# Step 1: Update the apt package index
echo "Updating apt package index..."
sudo apt-get update -y

# Step 2: Install packages to allow apt to use a repository over HTTPS
echo "Installing necessary packages for HTTPS repository..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Step 3: Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Step 4: Set up the stable Docker repository
echo "Setting up the stable Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt package index again after adding the new repository
echo "Updating apt package index with Docker repository..."
sudo apt-get update -y

# Step 5: Install Docker Engine, containerd, and Docker Compose
echo "Installing Docker Engine, containerd, and Docker Compose..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 6: Add your user to the 'docker' group
# This allows you to run Docker commands without sudo
echo "Adding current user to the 'docker' group..."
sudo usermod -aG docker "$USER"
echo "You need to log out and log back in for the group changes to take effect."
echo "Alternatively, run 'newgrp docker' to apply changes to your current session."

# Step 7: Verify the Docker installation
echo "Verifying Docker installation by running the hello-world image..."
# Run hello-world. Note: this command will likely fail until user logs out/in or runs newgrp docker
# To ensure the script completes without error, we'll check the service status instead.
# For a full test, the user needs to re-authenticate or use 'newgrp docker'.
echo "Checking if Docker service is active..."
sudo systemctl is-active docker || echo "Docker service is not active. Please check for errors or start it manually."

echo "Docker installation script finished."
echo "Please remember to log out and log back in (or run 'newgrp docker') to use Docker without 'sudo'."
