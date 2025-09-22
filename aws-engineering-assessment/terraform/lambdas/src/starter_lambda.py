import json
import urllib.parse
import boto3
import os

# Use LocalStack endpoint and fake credentials
sf_client = boto3.client(
    'stepfunctions',
    endpoint_url=os.getenv('LOCALSTACK_ENDPOINT', 'http://localhost:4566'),
    region_name='eu-central-1',
    aws_access_key_id='test',
    aws_secret_access_key='test'
)

def lambda_handler(event, context):
    STEP_FUNCTION_ARN = os.environ['STEP_FUNCTION_ARN']

    try:
        record = event['Records'][0]
        bucket_name = record['s3']['bucket']['name']
        file_key = urllib.parse.unquote_plus(record['s3']['object']['key'])


        # Print extracted values for debugging
        print("S3 bucket name:", bucket_name)
        print("S3 file key:", file_key)

        
        #make into payload  and push it step function to trigget the write_metadata_lambda in the workflow
        input_payload = {
            'bucket_name': bucket_name,
            'file_key': file_key
        }


        response = sf_client.start_execution(
            stateMachineArn=STEP_FUNCTION_ARN,
            input=json.dumps(input_payload)
        )

        safe_response = {
            'executionArn': response['executionArn'],
            'startDate': response['startDate'].isoformat()
        }

        print("Step Function started:", safe_response['executionArn'])
        return safe_response

    except Exception as e:
        print("Error starting Step Function:", e)
        raise e
