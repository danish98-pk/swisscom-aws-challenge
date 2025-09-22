import unittest
from unittest.mock import patch, MagicMock
from datetime import datetime

@patch.dict('os.environ', {'TABLE_NAME': 'file-metadata'})
class TestWriteMetadataLambda(unittest.TestCase):

    @patch('write_metadata_lambda.boto3')
    def test_lambda_handler_success(self, mock_boto3):
        mock_dynamodb = MagicMock()
        mock_table = MagicMock()
        mock_boto3.resource.return_value = mock_dynamodb
        mock_dynamodb.Table.return_value = mock_table

        event = {
            "bucket_name": "my-test-bucket",
            "file_key": "testfile.txt"
        }

        from write_metadata_lambda import lambda_handler
        response = lambda_handler(event, None)

        mock_dynamodb.Table.assert_called_with("file-metadata")
        mock_table.put_item.assert_called_once()
        args, kwargs = mock_table.put_item.call_args
        item = kwargs["Item"]

        self.assertEqual(item["Filename"], "testfile.txt")
        self.assertEqual(response["status"], "success")
        self.assertEqual(response["Filename"], "testfile.txt")
        self.assertIn("T", response["UploadTimestamp"])
