import unittest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError

@patch.dict('os.environ', {'SNS_TOPIC_ARN': 'arn:aws:sns:eu-central-1:123456789012:security-alerts'})
class TestCheckEncryptionLambda(unittest.TestCase):

    @patch('check_encryption_lambda.sns_client')
    @patch('check_encryption_lambda.ddb_client')
    @patch('check_encryption_lambda.s3_client')
    def test_unencrypted_resources(self, mock_s3, mock_ddb, mock_sns):
        mock_s3.exceptions = MagicMock()
        mock_s3.exceptions.ClientError = ClientError

        mock_s3.list_buckets.return_value = {'Buckets': [{'Name': 'unencrypted-bucket'}]}
        mock_s3.get_bucket_encryption.side_effect = ClientError(
            {"Error": {"Code": "ServerSideEncryptionConfigurationNotFoundError"}}, "GetBucketEncryption"
        )

        mock_ddb.list_tables.return_value = {'TableNames': ['unencrypted-table']}
        mock_ddb.describe_table.return_value = {'Table': {'TableName': 'unencrypted-table'}}

        mock_sns.publish.return_value = {"MessageId": "123"}

        from check_encryption_lambda import lambda_handler
        response = lambda_handler({}, None)

        self.assertEqual(response['status'], "Alert sent")
        self.assertIn("S3 Bucket 'unencrypted-bucket' is unencrypted", response['details'])
        self.assertIn("DynamoDB Table 'unencrypted-table' is unencrypted", response['details'])
        mock_sns.publish.assert_called_once()

    @patch('check_encryption_lambda.sns_client')
    @patch('check_encryption_lambda.ddb_client')
    @patch('check_encryption_lambda.s3_client')
    def test_all_encrypted(self, mock_s3, mock_ddb, mock_sns):
        mock_s3.list_buckets.return_value = {'Buckets': [{'Name': 'encrypted-bucket'}]}
        mock_s3.get_bucket_encryption.return_value = {"ServerSideEncryptionConfiguration": {}}

        mock_ddb.list_tables.return_value = {'TableNames': ['encrypted-table']}
        mock_ddb.describe_table.return_value = {
            'Table': {'TableName': 'encrypted-table', 'SSEDescription': {'Status': 'ENABLED'}}
        }

        from check_encryption_lambda import lambda_handler
        response = lambda_handler({}, None)

        self.assertEqual(response['status'], "All resources encrypted")
        mock_sns.publish.assert_not_called()
