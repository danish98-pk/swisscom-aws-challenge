locals {
  dynamodb_table_definition = {
    TableName            = "file-metadata"
    BillingMode          = "PAY_PER_REQUEST"
    AttributeDefinitions = [
      {
        AttributeName = "Filename"
        AttributeType = "S"
      }
    ]
    KeySchema = [
      {
        AttributeName = "Filename"
        KeyType       = "HASH"
      }
    ]
    SSESpecification = {
      Enabled        = true
      SSEType        = "KMS"
      KMSMasterKeyId = aws_kms_key.dynamodb_key.arn
    }
  }
}

#note:
resource "aws_kms_key" "dynamodb_key" {
  description = "KMS key for DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowRootAccountFullAccess",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::000000000000:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid       = "AllowDynamoDBToUseKeyForFileMetadataTable",
        Effect    = "Allow",
        Principal = {
          Service = "dynamodb.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:aws:dynamodb:tableName" = "file-metadata"
          }
        }
      },
      {
        Sid       = "AllowWorkerLambdaToUseKey",
        Effect    = "Allow",
        Principal = {
          AWS = aws_iam_role.worker_lambda_role.arn
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}



resource "null_resource" "dynamodb_table" {
  provisioner "local-exec" {
    command = "aws --endpoint-url=http://localhost:4566 dynamodb create-table --cli-input-json '${jsonencode(local.dynamodb_table_definition)}'"
  }
}





