resource "aws_iam_role" "sfn_role" {
  name = "sfn_role"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect    = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "sfn_policy"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["lambda:InvokeFunction"],
        Resource: aws_lambda_function.write_metadata.arn
      }
    ]
  })
}


resource "null_resource" "file_workflow" {
  provisioner "local-exec" {
    command = "aws --endpoint-url=http://localhost:4566 stepfunctions create-state-machine --name FileUploadWorkflow --role-arn ${aws_iam_role.sfn_role.arn} --definition '{\"Comment\":\"File metadata workflow\",\"StartAt\":\"WriteMetadata\",\"States\":{\"WriteMetadata\":{\"Type\":\"Task\",\"Resource\":\"${aws_lambda_function.write_metadata.arn}\",\"End\":true}}}'"
  }

  depends_on = [aws_lambda_function.write_metadata]
}
