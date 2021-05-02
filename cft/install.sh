#!/bin/bash

# Install kubectl
sudo curl --silent --location -o /usr/local/bin/kubectl https://sorinnginx.s3.eu-central-1.amazonaws.com/kubectl
sudo chmod +x /usr/local/bin/kubectl

# Install aws-iam-authenticator
sudo curl --silent --location -o /usr/local/bin/aws-iam-authenticator https://sorinnginx.s3.eu-central-1.amazonaws.com/aws-iam-authenticator
sudo chmod +x /usr/local/bin/aws-iam-authenticator

# Update awscli
sudo pip install --upgrade awscli && hash -r

# Install jq, envsubst (from GNU gettext utilities) and bash-completion
sudo yum -y install jq gettext bash-completion

# Enable kubectl bash_completion
kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# Install terraform
wget -O terraform.zip https://sorinnginx.s3.eu-central-1.amazonaws.com/terraform_0.12.19_linux_amd64.zip
unzip terraform.zip
rm terraform.zip
sudo mv terraform /usr/local/bin/

# Install Nginx Service Mesh
wget -O nginx-meshctl.gz https://sorinnginx.s3.eu-central-1.amazonaws.com/nginx-meshctl_linux.gz
gunzip nginx-meshctl.gz
rm nginx-meshctl.gz
sudo mv nginx-meshctl /usr/local/bin/
sudo chmod +x /usr/local/bin/nginx-meshctl



# Attach the IAM role to your Workspace
aws ec2 associate-iam-instance-profile --instance-id $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --iam-instance-profile Name=eksworkshop-admin



# To ensure temporary credentials aren’t already in place we will also remove any existing credentials file
rm -vf ${HOME}/.aws/credentials

# Generate SSH Key Pair
ssh-keygen -b 2048 -t rsa -f ~/eks.key -q -N "Much_S3cr3t-W0w1$"

# Verify the binaries are in path
for command in kubectl jq envsubst aws aws-iam-authenticator terraform nginx-meshctl
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done