#!/bin/bash
set -euo pipefail

ENDPOINT="http://localhost:4566"
REGION="eu-central-1"
TABLE_NAME="file-metadata"
BUCKET_NAME="file-upload-bucket"

echo "DynamoDB Cleanup"
if aws --endpoint-url=$ENDPOINT dynamodb describe-table \
   --region $REGION \
   --table-name $TABLE_NAME >/dev/null 2>&1; then


    aws --endpoint-url=$ENDPOINT dynamodb delete-table \
        --region $REGION \
        --table-name $TABLE_NAME

    aws --endpoint-url=$ENDPOINT dynamodb wait table-not-exists \
        --region $REGION \
        --table-name $TABLE_NAME
    echo "Table '$TABLE_NAME' deleted successfully."
else
    echo "Table '$TABLE_NAME' does not exist. Skipping deletion."
fi

echo "S3 Bucket Cleanup "
if aws --endpoint-url=$ENDPOINT s3api head-bucket \
   --bucket $BUCKET_NAME >/dev/null 2>&1; then
    echo "Bucket exists. Deleting all objects"
    aws --endpoint-url=$ENDPOINT s3 rm s3://$BUCKET_NAME --recursive --region $REGION
    echo "S3 bucket '$BUCKET_NAME' emptied."
else
    echo "Bucket '$BUCKET_NAME' does not exist"
fi

if [ -f "terraform.tfstate" ]; then
    echo "Running terraform destroy with auto-approve..."
    terraform destroy -auto-approve
    echo "Terraform destroy completed."
else
    echo "No Terraform state found. Skipping terraform destroy."
fi


