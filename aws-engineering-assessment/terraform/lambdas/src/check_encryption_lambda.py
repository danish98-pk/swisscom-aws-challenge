import boto3
import os

# LocalStack endpoints
sns_client = boto3.client('sns', endpoint_url='http://localhost:4566')
s3_client = boto3.client('s3', endpoint_url='http://localhost:4566')
ddb_client = boto3.client('dynamodb', endpoint_url='http://localhost:4566')

def lambda_handler(event, context):
    sns_arn = os.environ['SNS_TOPIC_ARN']

    unencrypted_resources = []

    # Check S3 buckets for encryption
    try:
        buckets = s3_client.list_buckets().get('Buckets', [])
        for bucket in buckets:
            try:
                s3_client.get_bucket_encryption(Bucket=bucket['Name'])
            except s3_client.exceptions.ClientError:
                unencrypted_resources.append(f"S3 Bucket '{bucket['Name']}' is unencrypted")
    except Exception as e:
        print("Error listing S3 buckets:", e)

    # Check DynamoDB tables for encryption
    try:
        tables = ddb_client.list_tables().get('TableNames', [])
        for table in tables:
            desc = ddb_client.describe_table(TableName=table)['Table']
            if 'SSEDescription' not in desc:
                unencrypted_resources.append(f"DynamoDB Table '{table}' is unencrypted")
    except Exception as e:
        print("Error listing DynamoDB tables:", e)

    # Send SNS alert if unencrypted resources found
    if unencrypted_resources:
        message = "\n".join(unencrypted_resources)
        print("Sending Security Alert:\n", message)
        sns_client.publish(
            TopicArn=sns_arn,
            Message=message,
            Subject="Security Alert"
        )
        return {"status": "Alert sent", "details": unencrypted_resources}

    return {"status": "All resources encrypted"}
