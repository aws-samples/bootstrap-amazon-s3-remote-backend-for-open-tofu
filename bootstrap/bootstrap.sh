#!/bin/bash

stage="dev"
infraDir="."
openTofuDir="${infraDir}/opentofu"
bootstrapDir="${infraDir}/bootstrap"
region="${1:-eu-central-1}" # Default to eu-central-1 if not provided

# Check if open-tofu (tofu) is installed
if ! command -v tofu &> /dev/null
then
    echo "Error: open-tofu (tofu) is not installed. Please install it and try again."
    exit 1
fi

# Check for valid AWS credentials
if ! aws sts get-caller-identity &> /dev/null
then
    echo "Error: Invalid AWS credentials. Please configure your AWS credentials and try again."
    exit 1
fi

stackName="${stage}-open-tofu-remote-backend"

echo "--- CloudFormation deploy ---"
aws cloudformation deploy --template-file "${bootstrapDir}/bootstrap.yaml" --stack "$stackName" --region "${region}"

echo "--- Get S3 bucket & DynamoDB table name for OpenTofu backend ---"
bucket=$(aws cloudformation describe-stacks --region "${region}" --query "Stacks[?StackName=='$stackName'][].Outputs[?OutputKey=='OpenTofuBackendBucketName'].OutputValue" --output text)
dbtable=$(aws cloudformation describe-stacks --region "${region}" --query "Stacks[?StackName=='$stackName'][].Outputs[?OutputKey=='OpenTofuBackendDynamoDBName'].OutputValue" --output text)

echo "S3 Bucket: $bucket"
echo "DynamoDB table: $dbtable"

echo "--- OpenTofu init ---"
tofu -chdir=$openTofuDir init -reconfigure -backend-config="bucket=${bucket}" -backend-config="region=${region}" -backend-config="dynamodb_table=${dbtable}" -upgrade

echo "--- OpenTofu plan ---"
tofu -chdir=$openTofuDir plan

echo "--- OpenTofu apply ---"
tofu -chdir=$openTofuDir apply
