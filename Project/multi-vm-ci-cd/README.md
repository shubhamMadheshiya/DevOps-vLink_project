# Multi-VM CI/CD Setup

This project provides a multi-VM setup using Vagrant to create a Continuous Integration and Continuous Deployment (CI/CD) environment. The setup includes three main components: Jenkins, Nexus, and SonarQube, along with PostgreSQL as the database for SonarQube and Nginx as a load balancer.

## Project Structure

```
multi-vm-ci-cd
├── Vagrantfile                # Defines the multi-VM setup and configurations
├── scripts                    # Contains setup scripts for each service
│   ├── jenkins-setup.sh      # Jenkins installation and configuration
│   ├── nexus-setup.sh        # Nexus installation and configuration
│   ├── sonarqube-setup.sh    # SonarQube installation and configuration
│   ├── postgresql-setup.sh    # PostgreSQL installation and configuration
│   └── nginx-setup.sh        # Nginx installation and configuration
├── README.md                  # Project documentation
└── security-groups            # Contains security group configurations
    └── group-config.md        # Security group rules for SSH connections
```

## Setup Instructions

1. **Install Vagrant and VirtualBox**: Ensure you have Vagrant and VirtualBox installed on your machine.

2. **Clone the Repository**: Clone this repository to your local machine.

3. **Navigate to the Project Directory**: Open a terminal and navigate to the `multi-vm-ci-cd` directory.

4. **Start the VMs**: Run the following command to start the VMs:
   ```
   vagrant up
   ```

5. **Access the VMs**: You can SSH into each VM using:
   ```
   vagrant ssh <vm-name>
   ```
   Replace `<vm-name>` with the name of the VM you want to access (e.g., `jenkins`, `nexus`, `sonarqube`).

## Usage

- **[Jenkins](http://192.168.56.10:8080)**: Access Jenkins through the web interface.
- **[Nexus](http://192.168.56.11:9081)**: Access Nexus through the web interface.
- **[SonarQube](http://192.168.56.12:80)**: Access SonarQube through the web interface.

## Security Groups

Refer to the `security-groups/group-config.md` file for details on the security group configurations that allow SSH connections between Jenkins, Nexus, and SonarQube servers.

## Additional Information

For further customization and configuration, you can modify the setup scripts located in the `scripts` directory. Each script is responsible for setting up its respective service.