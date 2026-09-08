# AWS Session Manager and RDS Tunnel Setup

A Bash utility for configuring AWS CLI SSO profiles, generating temporary database authentication tokens, and opening secure SSH tunnels to RDS through bastion hosts.

## Safety first

This script changes local AWS and SSH configuration and can connect to production infrastructure. Review the script and .env values before execution. Never commit .env, private keys, AWS credentials, or database tokens.

## Prerequisites

- Linux or macOS
- AWS CLI v2 with permission to configure SSO
- AWS Systems Manager Session Manager plugin
- curl, jq, ssh, and an existing bastion SSH key
- Access to the target AWS accounts and RDS security groups

## Usage

    git clone https://github.com/koushikbal/bash.git
    cd bash
    chmod +x sso_script1.sh
    ./sso_script1.sh

The script prompts for the target environment and establishes the selected tunnel locally.

## Configuration

Define these variables in a local, untracked .env: start_url, region, internal_role_name, internal_account_id, prod_role_name, prod_account_id, profile_internal, profile_production, username, key_file, key_strength, key_type, bastion_internal, bastion_production, rds_endpoint_dev, rds_endpoint_qa, rds_endpoint_rc, rds_endpoint_prod, rds_port, local_port, and bastion_user.

## Operational notes

Use least-privilege IAM roles, short-lived SSO sessions, and separate profiles for non-production and production. Validate the selected account and endpoint before opening a tunnel.
