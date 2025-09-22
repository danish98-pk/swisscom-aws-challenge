resource "aws_lambda_function" "starter_lambda" {
  filename         = "lambdas/zips/starter_lambda.zip"
  function_name    = "starter_lambda"
  handler          = "starter_lambda.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.starter_lambda_role.arn
  source_code_hash = filebase64sha256("lambdas/zips/starter_lambda.zip")
  timeout = 900 

  environment {
    variables = {
      STEP_FUNCTION_ARN = "arn:aws:states:eu-central-1:000000000000:stateMachine:FileUploadWorkflow"
    }
  }
}

resource "aws_lambda_function" "write_metadata" {
  filename         = "lambdas/zips/write_metadata_lambda.zip"
  function_name    = "write_metadata"
  handler          = "write_metadata_lambda.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.worker_lambda_role.arn
  source_code_hash = filebase64sha256("lambdas/zips/write_metadata_lambda.zip")
  timeout = 900 
}



# Lambda Function: check_encryption_lambda
resource "aws_lambda_function" "check_encryption_lambda" {
  filename         = "lambdas/zips/check_encryption_lambda.zip"
  function_name    = "check_encryption_lambda"
  handler          = "check_encryption_lambda.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.check_encryption_lambda_role.arn
  source_code_hash = filebase64sha256("lambdas/zips/check_encryption_lambda.zip")
  timeout          = 900

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}


