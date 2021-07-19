#!/bin/bash
pflag=false
rflag=false
fflag=false


DIRNAME=$(pwd)

usage () { echo "
    -h -- Opens up this help message
    -p -- Name of the AWS profile to use
    -r -- AWS Region to deploy to (e.g. eu-west-1)
    -f -- Name MP3 file to upload
"; }
options=':p:r:s:dfoch'
while getopts $options option
do
    case "$option" in
        p  ) pflag=true; PROFILE=${OPTARG};;
        r  ) rflag=true; REGION=${OPTARG};;
        f  ) fflag=true; FILE=${OPTARG};;
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

if ! $fflag
then
    echo "-f file to upload not specified, exiting" >&2
    exit 1
fi


ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text --profile ${PROFILE})
S3_UPLOAD_BUCKET=$(terraform output -json s3_uploads_bucket | tr -d '"')
S3_PROCESSED_BUCKET=$(terraform output -json s3_processed_bucket | tr -d '"')
STATUS_DYNAMO_TABLE=$(terraform output -json status_dynamo_table | tr -d '"')

echo "**************************
 starting uploader script
**************************
"
echo "account: ${ACCOUNT}"
echo "profile: ${PROFILE}"
echo "region: ${REGION}"
echo "file to upload: ${FILE}"
echo "s3 upload bucket: ${S3_UPLOAD_BUCKET}"
echo "s3 processed bucket: ${S3_PROCESSED_BUCKET}"
echo "status dynamo table: ${STATUS_DYNAMO_TABLE}"

# upload
# aws s3
