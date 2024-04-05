# AWS CLI and Session Manager Setup Script

This script automates the setup of AWS CLI and Session Manager Plugin, configures AWS SSO profiles, generates temporary DB authentication tokens, and sets up SSH tunneling for connecting to RDS instances securely.

## Prerequisites

Before running the script, ensure you have the following:

- Linux or macOS operating system.
- Access to AWS Console and necessary permissions to set up AWS CLI, Session Manager, and AWS SSO.
- `curl` installed (will be installed if not already present).
- `.env` file with required variables (see below for the list).

## Usage

1. Clone the repository:

    ```bash
    git clone https://github.com/yourusername/your-repo.git
    cd your-repo
    ```

2. Make sure your `.env` file is in the same directory as the script. If not, create one with the required variables (see below).

3. Run the script:

    ```bash
    bash setup.sh
    ```

4. Follow the prompts to select RDS endpoint and complete the setup.

## Environment Variables

Ensure your `.env` file contains the following variables:

- `start_url`: AWS SSO start URL.
- `region`: AWS region.
- `internal_role_name`: Role name for internal AWS SSO profile.
- `internal_account_id`: AWS account ID for internal AWS SSO profile.
- `prod_role_name`: Role name for production AWS SSO profile.
- `prod_account_id`: AWS account ID for production AWS SSO profile.
- `profile_internal`: Name for the internal AWS SSO profile.
- `profile_production`: Name for the production AWS SSO profile.
- `username`: Database username.
- `key_file`: Path to SSH key file.
- `key_strength`: Strength of SSH key (e.g., 2048).
- `key_type`: Type of SSH key (e.g., rsa).
- `bastion_internal`: Bastion host for internal profile.
- `bastion_production`: Bastion host for production profile.
- `rds_endpoint_dev`: RDS endpoint for development environment.
- `rds_endpoint_qa`: RDS endpoint for QA environment.
- `rds_endpoint_rc`: RDS endpoint for rc environment.
- `rds_endpoint_prod`: RDS endpoint for production environment.
- `rds_port`: RDS port (default: 5432).
- `local_port`: Local port for SSH tunneling.
- `bastion_user`: Username for the bastion host.
