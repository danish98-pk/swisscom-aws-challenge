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


# resource "aws_dynamodb_table" "file_metadata" {
#   name         = "file-metadata"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "Filename"

#   attribute {
#     name = "Filename"
#     type = "S"
#   }

#   server_side_encryption {
#     enabled     = true
#     kms_key_arn = aws_kms_key.dynamodb_key.arn
#   }
# }


#LocalStack making things worst for now , leveraging null resource { provisioner method}
resource "null_resource" "dynamodb_table" {
  provisioner "local-exec" {
    command = "aws --endpoint-url=http://localhost:4566 dynamodb create-table --table-name file-metadata --attribute-definitions AttributeName=Filename,AttributeType=S --key-schema AttributeName=Filename,KeyType=HASH --billing-mode PAY_PER_REQUEST  --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=${aws_kms_key.dynamodb_key.arn}"
  }
}




