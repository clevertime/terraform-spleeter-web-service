#!/bin/bash
pflag=false
rflag=false
sflag=false

DIRNAME=$(pwd)

usage () { echo "
    -h -- Opens up this help message
    -p -- Name of the AWS profile to use
    -r -- AWS Region to deploy to (e.g. eu-west-1)
    -s -- AWS subnets to deploy resources to (e.g. -s subnet-xxxxxxxx,subnet-yyyyyyyy)
"; }
options=':p:r:s:dfoch'
while getopts $options option
do
    case "$option" in
        p  ) pflag=true; PROFILE=${OPTARG};;
        r  ) rflag=true; REGION=${OPTARG};;
        s  ) sflag=true; SUBNETS=${OPTARG};;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ! $pflag
then
    echo "-p not specified, using default..." >&2
    PROFILE="default"
fi
if ! $rflag
then
    echo "-r not specified, using default region..." >&2
    REGION=$(aws configure get region --profile ${PROFILE})
fi

if ! $sflag
then
    echo "-s subnets not specified, exiting" >&2
    exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text --profile ${PROFILE})

echo "**************************
 starting helper script to deploy the 'spleeter-web-service' via docker & terraform
**************************
"
echo "account: ${ACCOUNT}"
echo "profile: ${PROFILE}"
echo "region: ${REGION}"
echo "subnets: ${SUBNETS}"

function create_tf_aws_provider()
{
  echo 'provider "aws" {
  region  = "'$REGION'"
  profile = "'$PROFILE'"
}
' > provider.tf
}

function create_tfvars()
{
  FORMATTED_SUBNETS=$(python -c 'import sys; import json; print(json.dumps(sys.argv[1].split(",")))' ${SUBNETS})
  echo "subnets = "$FORMATTED_SUBNETS > terraform.tfvars
}

function terraform_run_ecs()
{
  terraform init
  terraform apply -target=aws_ecr_repository.this
}

function docker_build_push()
{
  ECR_REPOSITORY_URL=$1
  cd spleeter-docker
  docker build -t spleeter-web-service .
  docker tag spleeter-web-service:latest $ECR_REPOSITORY_URL
  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL
  echo "[*] pushing docker image to ${ECR_REPOSITORY_URL}"
  docker push $ECR_REPOSITORY_URL
  cd ..
}

function terraform_run_all()
{
  terraform init
  terraform apply
}

echo "[*] creating provider file..."
create_tf_aws_provider

echo "[*] creating terraform variables file..."
create_tfvars

echo "[*] deploying ecr repository with terraform..."
terraform_run_ecs

echo "[*] build docker image..."
TF_ECR_REPOSITORY_URL=$(terraform output -json ecr_repository_url | tr -d '"')
docker_build_push $TF_ECR_REPOSITORY_URL

echo "[*] adding docker image uri to 'terraform.tfvars'"
echo 'docker_ecs_uri = "'$TF_ECR_REPOSITORY_URL'"' >> terraform.tfvars

echo "[*] building infrastructure with terraform..."
terraform_run_all
