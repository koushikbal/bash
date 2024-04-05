#! /bin/bash

# Check if curl is installed
if command -v curl &>/dev/null; then
    echo "curl is already installed."
else
    # Install curl using the package manager (apt in this case)
    echo "curl is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y curl
fi
curl_version=$(curl --version | head -n 1)
echo "Installed curl version: $curl_version"

#.env file
if [ -f sso.env ]; then
    source sso.env
else
    echo "Error: .env file not found. Please create one with the required variables."
    exit 1
fi

# Function to check if a command is available
command_exists() {
  command -v "$1" &> /dev/null
}

# Check if AWS CLI is already installed
if command_exists "aws"; then
  echo "AWS CLI is already installed."
else
  echo "Installing AWS CLI..."
  # Install on Linux
  if [[ $(uname -s) == "Linux" ]]; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    aws --version
  # Install on macOS
  elif [[ $(uname -s) == "Darwin" ]]; then
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg ./AWSCLIV2.pkg -target /
    aws --version
  else
    echo "Unsupported operating system."
    exit 1
  fi
  echo "AWS CLI has been installed."
fi

# Check if Session Manager plugin is already installed
if command_exists "session-manager-plugin"; then
  echo "Session Manager plugin is already installed."
else
  echo "Installing Session Manager plugin..."
  # Install on Linux
  if [[ $(uname -s) == "Linux" ]]; then
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    sudo dpkg -i session-manager-plugin.deb
    rm -rf session-manager-plugin.deb
    session-manager-plugin
  # Install on macOS
  elif [[ $(uname -s) == "Darwin" ]]; then
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
    unzip sessionmanager-bundle.zip
    sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
    session-manager-plugin
  else
    echo "Unsupported operating system."
    exit 1
  fi
  echo "Session Manager plugin has been installed."
fi
echo "AWS CLI and Session Manager plugin are installed."

# Check if profiles already exist
if aws configure get sso_start_url --profile $profile_internal &> /dev/null && aws configure get sso_start_url --profile $profile_production &> /dev/null; then
 echo "Profiles 'internal' and 'production' already exist."
else
 echo "setting up profiles." 
  # Set up AWS SSO configuration for the 'internal' profile
aws configure --profile $profile_internal set sso_start_url $start_url
aws configure --profile $profile_internal set sso_region $region
aws configure --profile $profile_internal set sso_role_name $internal_role_name
aws configure --profile $profile_internal set sso_account_id $internal_account_id
aws configure --profile $profile_internal set region $region
aws configure --profile $profile_internal set output json

  # Set up AWS SSO configuration for the 'production' profile
aws configure --profile $profile_production set sso_start_url $start_url
aws configure --profile $profile_production set sso_region $region
aws configure --profile $profile_production set sso_role_name $prod_role_name
aws configure --profile $profile_production set sso_account_id $prod_account_id
aws configure --profile $profile_production set region $region
aws configure --profile $profile_production set output json
echo "Profiles $profile_internal & $profile_production created"
fi

# Display RDS options
echo "Available RDS endpoints:"
echo "1. dev"
echo "2. qa"
echo "3. rc"
echo "4. prod"

# Prompt user to choose an RDS endpoint
read -p "Choose an RDS endpoint (enter the number): " rds_choice

# Validate user input
case $rds_choice in
  1)
    profile=$profile_internal
    bastion_host=$bastion_internal
    rds_endpoint=$rds_endpoint_dev
    generate_token=true
    ;;
  2)
    profile=$profile_internal
    bastion_host=$bastion_internal
    rds_endpoint=$rds_endpoint_qa
    generate_token=true
    ;;
  3)
    profile=$profile_production
    bastion_host=$bastion_production
    rds_endpoint=$rds_endpoint_rc
    generate_token=true
    ;;
  4)
    profile=$profile_production
    bastion_host=$bastion_production
    rds_endpoint=$rds_endpoint_prod
    generate_token=true    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# login to aws-cli profile and exporting the profile
aws sso login --profile $profile
export AWS_PROFILE=$profile

echo "Automatically chosen profile: $profile"
echo "Selected RDS endpoint: $rds_endpoint"
echo "Automatically chosen bastion host: $bastion_host"

# Generate a temporary DB authentication token
if [ "$generate_token" = true ]; then
token="$(aws rds generate-db-auth-token --hostname $rds_endpoint --port $rds_port --region $region --username $username )"
else
  echo "No DB Auth Token needed for $rds_endpoint."
fi

# Check if the SSH key already exists
if [ -f "$key_file" ]; then
    echo "SSH key already exists at: $key_file"
else
    # Generate the SSH key using ssh-keygen command
    ssh-keygen -b $key_strength -t $key_type -f "$key_file"

    # Print a message indicating successful key generation
    echo "SSH key generated successfully at: $key_file"
fi

# SSH file configuration for ec2-proxy-command and config_file
if [ -f "$SCRIPT_PATH" ]; then
  echo "Script file already exists: $SCRIPT_PATH"
else
  cat << 'EOF' > "$SCRIPT_PATH"
set -eu

REGION_SEPARATOR='--'

ec2_instance_id="$1"
ssh_user="$2"
ssh_port="$3"
ssh_public_key_path="$4"
ssh_public_key="$(cat "${ssh_public_key_path}")"
ssh_public_key_timeout=60

if [[ "${ec2_instance_id}" == *"${REGION_SEPARATOR}"* ]]; then
  export AWS_DEFAULT_REGION="${ec2_instance_id##*${REGION_SEPARATOR}}"
  ec2_instance_id="${ec2_instance_id%%${REGION_SEPARATOR}*}"
fi

>/dev/stderr echo "Add public key ${ssh_public_key_path} for ${ssh_user} at instance ${ec2_instance_id} for ${ssh_public_key_timeout} seconds"
aws ssm send-command \
  --instance-ids "${ec2_instance_id}" \
  --document-name 'AWS-RunShellScript' \
  --comment "Add an SSH public key to authorized_keys for ${ssh_public_key_timeout} seconds" \
  --parameters commands="\"
    mkdir -p ~${ssh_user}/.ssh && cd ~${ssh_user}/.ssh || exit 1

    authorized_key='${ssh_public_key} ssm-session'
    echo \\\"\${authorized_key}\\\" >> authorized_keys

    sleep ${ssh_public_key_timeout}

    grep -v -F \\\"\${authorized_key}\\\" authorized_keys > .authorized_keys
    mv .authorized_keys authorized_keys
  \""

>/dev/stderr echo "Start ssm session to instance ${ec2_instance_id}"
aws ssm start-session \
  --target "${ec2_instance_id}" \
  --document-name 'AWS-StartSSHSession' \
  --parameters "portNumber=${ssh_port}"
EOF

chmod +x ~/.ssh/aws-ssm-ec2-proxy-command.sh

echo "Script has been created: ~/.ssh/aws-ssm-ec2-proxy-command.sh"
fi

# SSH Config
if [ -f "$CONFIG_PATH" ]; then
  echo "Config file already exists: $CONFIG_PATH"
else
  cat << 'EOF' > "$CONFIG_PATH"
host i-* mi-*
  IdentityFile ~/.ssh/id_rsa
  ProxyCommand ~/.ssh/aws-ssm-ec2-proxy-command.sh %h %r %p ~/.ssh/id_rsa.pub
  StrictHostKeyChecking no
EOF

  echo "Config file has been created: $CONFIG_PATH"
fi

#DB_TOKEN
echo "Temporary DB Auth Token::$token"

# SSH tunneling and connect to RDS
ssh -L $local_port:$rds_endpoint:$rds_port $bastion_user@$bastion_host
