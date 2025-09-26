### Clone the Repository  

Start by cloning this repository to your Ubuntu Machine . This project has been tested on Ubuntu

```bash
git clone https://github.com/danish98-pk/swisscom-aws-challenge.git
cd swisscom-aws-challenge/aws-engineering-assessment
```

#### ✅ Prerequisites  
#### 📌 What  Setup.sh  does  
1. **Creates a Python virtual environment** named `awscli_venv` to isolate dependencies.
2. Installs python3 and pip3
3. **Installs AWS CLI
4. **Activates the virtual environment** so you can immediately use AWS CLI

> **Note:** This is required to run `null_resource` using `local-exec` as a Terraform wrapper for executing AWS CLI commands to provision a DynamoDB table and Step Function.
---


#### ▶️ Usage  

Make the script executable and run it:  

```bash
chmod +x setup.sh
source ./setup.sh
```


## Setup  Terraform Infrastructure 

install docker-compose  if not installed
```bash
sudo apt install docker-compose -y
```


```bash
cd terraform/
sudo docker-compose up -d
```

### Install Terraform if not installed
```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Setup Fake AWS Profile
```bash
aws configure set aws_access_key_id foobar
aws configure set aws_secret_access_key foobar
aws configure set region eu-central-1
aws configure set output json
```


### Initialize and Apply Infrastructure
```bash
terraform init
terraform plan
terraform apply
```



## To do the cleanups ( destroying infra )

run the cleanup.sh script under terraform folder

```bash
chmod +X cleanup.sh
./cleanup.sh
```


if you have setup Prerequisites steps then run this to deactivate virtual environment
```bash
deactivate
```


## Arhcitecture Diagram 
<img width="1227" height="737" alt="image" src="https://github.com/user-attachments/assets/863dedf8-7ba6-4272-8b5f-e921413001d8" />


## 🛠 Terraform Infrastructure Overview

This project uses **Terraform** to provision the entire AWS infrastructure locally via **LocalStack**.  
Below is a breakdown of the main `.tf` files and their responsibilities.

---

### `provider.tf`
Configures the **AWS provider** to point to LocalStack endpoints.

- Sets static `access_key` and `secret_key` for LocalStack.
- Specifies region: `eu-central-1`.
- Configures LocalStack service endpoints for all AWS services used (S3, Lambda, DynamoDB, Step Functions, KMS, SNS, etc.).
- Ensures Terraform interacts entirely with **LocalStack**, not real AWS.

---

### 'variables.tf'

reusable variables

### `dynamodb.tf`
Manages DynamoDB table creation and encryption:

- Uses a `null_resource` with `local-exec` as a workaround to create the DynamoDB table via AWS CLI with SSE enabled.

---

### `iam.tf`
Creates IAM roles and policies for Lambdas and Step Functions:

- **starter_lambda_role** — Can invoke Step Functions 
- **worker_lambda_role** — Can write metadata to DynamoDB 
- **check_encryption_lambda_role** — Can scan all S3 buckets and DynamoDB tables for encryption, publish alerts to SNS.  

---

### `lambda.tf`
Deploys Lambda functions:

- `starter_lambda` — Triggered by S3 events, starts the Step Function execution.  
- `write_metadata` — Writes metadata to DynamoDB table.  
- `check_encryption_lambda` — Scans S3 and DynamoDB for unencrypted resources and publishes alerts to SNS.  

---

### `s3.tf`
Creates S3 bucket and configures encryption and lifecycle:

---

### `s3-event.tf`

aws_s3_bucket_notification.s3_event — Triggers starter_lambda on s3:ObjectCreated:* events.

---

### `sns.tf`
Creates SNS topic and email subscription:

 Sends alert emails to  awssecops123@gmail.com   

---

### `stepfunction.tf`

Step Function execution role.  
null_resource.file_workflow — Creates Step Function using AWS CLI with `WriteMetadata` task pointing to `write_metadata_lambda`.  
setup error handling

---

### `terraform/lambdas/src/`
Contains Lambda source code:

- `starter_lambda.py` — Trigger Lambda, starts Step Function on S3 file upload.  
- `write_metadata_lambda.py` — Writes file metadata (filename + timestamp) to DynamoDB.  
- `check_encryption_lambda.py` — Audits encryption of S3 buckets and DynamoDB tables; publishes SNS alerts.  

---

### `terraform/lambdas/zips/`
Pre-packaged Lambda zip files:

- `starter_lambda.zip`  
- `write_metadata_lambda.zip`  
- `check_encryption_lambda.zip`  

Used in `lambda.tf` for deployment.

---
Unit tests for Lambdas:

- `test_check_encryption_lambda.py` — Validates detection of unencrypted resources.  
- `test_starter_lambda.py` — Ensures Step Function is triggered properly.  
- `test_write_metadata_lambda.py` — Confirms metadata is correctly written to DynamoDB.

To run unit test. Under terraform folder switch to lambdas/src/
```bash
cd lambdas/src/
```
```bash
pytest test_check_encryption_lambda.py -v -s 
pytest test_starter_lambda.py -v -s
pytest test_write_metadata_lambda.py -v -s
```


---

### Run these commands for Validation

To list s3 buckets
```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

Check bucket object
```bash
aws --endpoint-url=http://localhost:4566 s3 ls s3://file-upload-bucket
```

upload file to s3 bucket
```bash
aws --endpoint-url=http://localhost:4566 s3 cp README.md s3://file-upload-bucket/
```

Check s3 lifecycle
```bash
aws --endpoint-url=http://localhost:4566 s3api get-bucket-lifecycle-configuration --bucket file-upload-bucket
```



step function execution status . once you got the output , grab the execution arn for the next command
```bash
 aws --endpoint-url=http://localhost:4566 stepfunctions list-executions \
    --state-machine-arn arn:aws:states:eu-central-1:000000000000:stateMachine:FileUploadWorkflow
```
Describe stepfunction execution
```bash
aws --endpoint-url=http://localhost:4566 stepfunctions describe-execution \
    --execution-arn "<Execution-arn-of-step-function"
```

List tables
```bash
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

dynamodb file validation
```bash
 aws --endpoint-url=http://localhost:4566 dynamodb scan \
    --table-name file-metadata
```

To Test unencrypted Buckets and Tables 

s3
```bash
aws --endpoint-url=http://localhost:4566 s3api create-bucket \
    --bucket my-unencrypted-bucket \
    --create-bucket-configuration LocationConstraint=eu-central-1
```

Dynamodb Table
```bash
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name unencrypted-table \
    --attribute-definitions AttributeName=Id,AttributeType=S \
    --key-schema AttributeName=Id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

List Lambda Functions
```bash
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

To trigger the check encryption lambda function manually
```
aws --endpoint-url=http://localhost:4566 lambda invoke \
    --function-name check_encryption_lambda \
    output.json
```

#check logs of the lambda in log group . You will be able to see the lambda grabbed the unencrypted resources and sent alert to the sns
```bash
aws --endpoint-url=http://localhost:4566 logs filter-log-events \
  --log-group-name /aws/lambda/check_encryption_lambda \
  --limit 20 \
  --region eu-central-1
```

list sns
```bash
 aws --endpoint-url=http://localhost:4566 sns list-topics \
  --region eu-central-1
```
You can verify the alert has been sent by looking at the path volume/tmp//state/ses/ . You can cat the json file and see the ouput as mentioned below
###Output
```bash
{"Id": "mxfthwwscyulscvr-hcxdfclb-vfxy-aglj-oovq-knnvxluzlvds-erzqjg", "Timestamp": "2025-09-22T09:59:42", "Region": "eu-central-1", "Source": "admin@localstack.com", "Destination": {"ToAddresses": ["awssecops123@gmail.com"]}, "Subject": "SNS-Subscriber-Endpoint", "Body": {"text_part": "S3 Bucket 'my-unencrypted-bucket' is unencrypted", "html_part": null}}
```



#####
To test StepFunction Error Handling  , provided empty input to step function which will fail the lambda and stepfunction will do the error handling
```bash
aws --endpoint-url=http://localhost:4566 stepfunctions start-execution \
  --state-machine-arn arn:aws:states:eu-central-1:000000000000:stateMachine:FileUploadWorkflow \
  --name test-validation-error \
  --input '{}'
```
List down the failed stepfunction to check the error handling , grab the execution arn of it and paste it in this command
```bash
aws --endpoint-url=http://localhost:4566 stepfunctions describe-execution \
  --execution-arn <EXECUTION_ARN>
```
You can also list all events from this failed execution arn
```bash
aws --endpoint-url=http://localhost:4566 stepfunctions get-execution-history \
  --execution-arn <EXECUTION_ARN>
```


### CLOUDFORMATION TASK



The cloudformation Template has been updated with new features:

- **Main S3 Bucket**
  - encryption
  - Logging enabled to a dedicated logging bucket
  - Fine-grained bucket policy restricting access to the account only

- **Logging Bucket**
  - Dedicated bucket to store access logs for the main bucket
  - encryption
  - Bucket policy allows logging service  to write logs
 
# To run Cloudfomration Project

- Make sure to run setup.sh script like we did for the terraform project under aws-engineering-assessment folder to avoid package conflicts.
- Run Setup fake credentials step
- Run docker-compose installation step if not installed






 







