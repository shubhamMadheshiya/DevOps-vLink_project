# Ansible Workspace

This Ansible workspace is structured to facilitate the management and automation of tasks across multiple hosts. Below is a brief overview of the components included in this project.

## Directory Structure

- **inventories/**: Contains the inventory files that define the hosts and groups of hosts.
  - **hosts.ini**: Specifies the groups of hosts and their connection details.

- **playbooks/**: Contains the playbooks that define the tasks to be executed.
  - **site.yml**: The main playbook for the Ansible project.

- **roles/**: Contains the roles used in the Ansible project.
  - **README.md**: Documentation for the roles, describing their purpose and usage.

- **group_vars/**: Contains variable files that apply to all hosts.
  - **all.yml**: Centralized variable management for all hosts.

- **ansible.cfg**: The configuration file for Ansible, specifying settings such as inventory location and roles path.

## Setup Instructions

1. Clone the repository to your local machine.
2. Navigate to the `ansible-workspace` directory.
3. Update the `inventories/hosts.ini` file with your host details.
4. Modify the `group_vars/all.yml` file to set any necessary variables.
5. Customize the `playbooks/site.yml` file with the tasks you want to execute.
6. Run the playbook using the command:
   ```
   ansible-playbook playbooks/site.yml
   ```

## Usage Guidelines

- Ensure that you have Ansible installed on your machine.
- Review the `ansible.cfg` file to adjust any configurations as needed.
- Use the roles defined in the `roles/` directory to modularize your tasks and promote reusability.
- Refer to the `roles/README.md` for detailed information on each role's usage.

This workspace is designed to streamline your automation tasks and improve efficiency in managing your infrastructure.