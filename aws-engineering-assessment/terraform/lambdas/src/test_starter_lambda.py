import unittest
from unittest.mock import patch, MagicMock

@patch.dict('os.environ', {'STEP_FUNCTION_ARN': 'arn:aws:states:eu-central-1:123456789012:stateMachine:myStateMachine'})
class TestStarterLambda(unittest.TestCase):

    @patch('starter_lambda.sf_client')
    def test_lambda_handler_success(self, mock_sf_client):
        mock_sf_client.start_execution.return_value = {
            'executionArn': 'arn:aws:states:eu-central-1:123456789012:execution:myStateMachine:execution123',
            'startDate': MagicMock(isoformat=lambda: '2025-09-20T12:00:00')
        }

        event = {
            'Records': [{
                's3': {
                    'bucket': {'name': 'my-bucket'},
                    'object': {'key': 'test%20file.txt'}
                }
            }]
        }

        from starter_lambda import lambda_handler
        response = lambda_handler(event, None)

        mock_sf_client.start_execution.assert_called_once()
        self.assertEqual(response['executionArn'], 'arn:aws:states:eu-central-1:123456789012:execution:myStateMachine:execution123')
        self.assertEqual(response['startDate'], '2025-09-20T12:00:00')
