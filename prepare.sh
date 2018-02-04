#!/bin/bash -eu

AWS_ACCOUNT_NAME='mazgi-sakemeshi-aws'
TERRAFORM_VERSION='0.11.3'

if [[ ! -f bin/terraform ]]; then
  if [[ "$(uname)" = "Darwin" ]]; then
    ARCH_NAME='darwin_amd64'
  else
    ARCH_NAME='linux_amd64'
  fi
  TERRAFORM_DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${ARCH_NAME}.zip"
  curl -Lo /tmp/terraform.zip "${TERRAFORM_DOWNLOAD_URL}"
  mkdir -p bin
  unzip /tmp/terraform.zip -d bin/
fi

export AWS_ACCESS_KEY_ID=$(tail -1 secret/${AWS_ACCOUNT_NAME}.terraform-admin.credentials.csv | cut -d, -f3)
export AWS_SECRET_ACCESS_KEY=$(tail -1 secret/${AWS_ACCOUNT_NAME}.terraform-admin.credentials.csv | cut -d, -f4)
echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
