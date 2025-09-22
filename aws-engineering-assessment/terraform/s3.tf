locals {
  s3_lifecycle_config = jsonencode({
    Rules = [
      {
        ID     = "expire-old-objects"
        Status = "Enabled"
        Filter = {}
        Expiration = {
          Days = 90
        }
      }
    ]
  })
}


#scoped down
resource "aws_kms_key" "s3_key" {
  description = "KMS key for S3 bucket encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      #  Root account has full access
      {
        Sid       = "AllowRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::000000000000:root" }
        Action    = "kms:*"
        Resource  = "*" 
      },
      {
        Sid       = "AllowLambdaUse"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.starter_lambda_role.arn }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }

    ]
  })
}


# S3 bucket
resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name
}

# Server-side encryption using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads_sse" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.id
    }

  }
}


# Null resource to apply lifecycle configuration via AWS CLI { Somehow the LocalStack is not liking lifecycle configuration resource type block , we have to do it another way by using aws cli command}
#https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-lifecycle-configuration.html

resource "null_resource" "s3_lifecycle" {
  depends_on = [aws_s3_bucket.uploads]

  provisioner "local-exec" {
    command = "aws --endpoint-url=http://localhost:4566 s3api put-bucket-lifecycle-configuration --bucket ${aws_s3_bucket.uploads.id} --lifecycle-configuration '${local.s3_lifecycle_config}'"
  }
}





