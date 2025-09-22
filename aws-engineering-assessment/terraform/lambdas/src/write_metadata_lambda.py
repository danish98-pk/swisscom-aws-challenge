import boto3
from datetime import datetime
import os

def lambda_handler(event, context):
    TABLE_NAME = os.environ.get('TABLE_NAME', 'file-metadata')

    bucket = event['bucket_name']
    key = event['file_key']


    # Print extracted values for debugging
    print("S3 bucket name:", bucket)
    print("S3 file key:", key)

    # Current timestamp as string
    upload_time = datetime.utcnow().isoformat()

    # Connect to LocalStack DynamoDB
    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=os.getenv('LOCALSTACK_ENDPOINT', 'http://localhost:4566'),
        region_name='eu-central-1',
        aws_access_key_id='test',
        aws_secret_access_key='test'
    )

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            "Filename": key,
            "UploadTimestamp": upload_time
        }
    )
    print(f"Metadata written for file {key} in bucket {bucket}")

    return {
        "status": "success",
        "Filename": key,
        "UploadTimestamp": upload_time
    }
