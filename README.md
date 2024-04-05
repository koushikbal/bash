AWS SSO Automation & RDS Tunneling

Introduction:
This bash script automates the setup of AWS CLI, AWS SSO, and establishes a secure SSH tunnel to access RDS instances securely. It streamlines the process of configuring AWS profiles, installing necessary tools like AWS CLI and Session Manager plugin, and setting up SSH keys for secure RDS access through a bastion host.

Prerequisites:
Linux or macOS operating system
Bash shell
AWS CLI
Access to AWS SSO portal
Access to AWS resources (RDS, EC2 instances)

Installation:
Clone this repository to your local machine.
Ensure you have curl installed. If not, it will be installed automatically.
Ensure you have necessary permissions to install packages and execute scripts with sudo.
Create an .env file with required variables (see .env.example for reference).
Run the script setup.sh using the command bash setup.sh.
Follow the prompts to configure AWS profiles and select RDS endpoints.

Usage:
After running the setup script, you can easily access RDS instances through SSH tunneling without exposing database endpoints.
Choose RDS endpoints from the provided options and follow the instructions to establish a secure connection.

Features:
Automatic installation of AWS CLI and Session Manager plugin.
Seamless configuration of AWS SSO profiles for different environments.
Secure SSH tunneling for accessing RDS instances via a bastion host.
Customizable SSH key generation and configuration.
