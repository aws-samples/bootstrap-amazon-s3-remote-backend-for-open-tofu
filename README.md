# OpenTofu Infrastructure Bootstrap

OpenTofu is a Terraform fork, created as an initiative of Gruntwork, Spacelift, Harness, Env0, Scalr, and others, in response to HashiCorp’s switch from an open-source license to the BUSL.
This project provides the necessary scripts and [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) templates to set up a secure and robust Amazon S3 remote backend for [OpenTofu](https://opentofu.org/).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
  - [Deploying the Infrastructure](#deploying-the-infrastructure)
  - [Understanding the Files](#understanding-the-files)
- [CloudFormation Stack Details](#cloudformation-stack-details)
- [Outputs](#outputs)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Prerequisites

Before running the bootstrap script, ensure you have the following:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) installed and configured
- [OpenTofu CLI installed](https://opentofu.org/docs/intro/install)
- Valid AWS credentials for an Role, see [Use an IAM role in the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html), having at least the following permissions:

<details>
<summary>Click here to view the minimum permission which are required to execute the code</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AmazonS3",
            "Effect": "Allow",
            "Action": [
                "s3:PutEncryptionConfiguration",
                "s3:PutBucketLogging",
                "s3:PutLifecycleConfiguration",
                "s3:PutBucketPolicy",
                "s3:ListBucket",
                "s3:PutBucketVersioning",
                "cloudformation:ExecuteChangeSet",
                "s3:CreateBucket",
                "s3:GetBucketLogging",
                "s3:GetBucketPolicy",
                "s3:GetBucketPolicyStatus",
                "s3:GetBucketTagging",
                "s3:GetBucketVersioning",
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:GetBucketOwnershipControls",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetLifecycleConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:ListTagsForResource",
                "s3:TagResource",
                "s3:GetIntelligentTieringConfiguration",
                "s3:UntagResource",
                "s3:GetBucketAcl",
                "s3:ListAccessPoints",
                "s3:GetAccountPublicAccessBlock",
                "s3:PutBucketPublicAccessBlock"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Sid": "S3Object",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*/*"
        },
        {
            "Sid": "DynamoDB",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:DescribeTable",
                "dynamodb:ListTables",
                "dynamodb:CreateTable",
                "dynamodb:PutItem",
                "dynamodb:TagResource",
                "dynamodb:UntagResource",
                "dynamodb:UpdateContinuousBackups",
                "dynamodb:DescribeContinuousBackups",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "KMS",
            "Effect": "Allow",
            "Action": [
                "kms:CreateKey",
                "kms:CreateAlias",
                "kms:PutKeyPolicy",
                "kms:ListAliases",
                "kms:ListKeys",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:DescribeKey",
                "kms:ListGrants",
                "kms:Encrypt",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:CreateKey",
                "kms:ListKeyPolicies",
                "kms:GetKeyPolicy",
                "kms:PutKeyPolicy",
                "kms:EnableKey",
                "kms:CreateGrant",
                "kms:Decrypt",
                "kms:GenerateDataKey"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "CloudFormation",
            "Effect": "Allow",
            "Action": [
                "cloudformation:DescribeStacks",
                "cloudformation:ListStacks",
                "cloudformation:CreateChangeSet",
                "cloudformation:CreateStack",
                "cloudformation:TagResource",
                "cloudformation:UntagResource",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:GetTemplateSummary"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
</details>

## Setup

Clone the repository and navigate to the bootstrap directory:

````bash
git clone https://github.com/<to fill out>/open-tofu-bootstrap.git
````

## Usage

The [bootstrap.sh](/bootstrap/bootstrap.sh) script is used to initialize and apply the OpenTofu backend infrastructure.

### Deploying the Infrastructure

To deploy the OpenTofu infrastructure, execute the subsequent command. The region argument is optional and defaults to `eu-central-1`:

```shell
bash bootstrap/bootstrap.sh <aws-region>
```

This script performs the following actions:

- Deploys the [bootstrap.yaml](/bootstrap/bootstrap.yaml) CloudFormation template.
- Retrieves and prints out the S3 bucket and DynamoDB table names.
- Initializes and applies OpenTofu backend configuration.

### Understanding the Files

- `bootstrap.sh`: Shell script to orchestrate the bootstrap process.
- `bootstrap.yaml`: CloudFormation template that defines the required AWS resources.

## CloudFormation Stack Details

The `bootstrap.yaml` template will create:

- Two [Amazon S3 Buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html):
  - one for OpenTofu state remote storage, and
  - one for access logs.
- One [Amazon KMS Key](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) for S3 bucket encryption.
- One [Amazon DynamoDB Table](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html) for state locking.

Resources come with retain policies to prevent accidental deletion.


### Architecture

![OpenTofu remote backend](/assets/OpenTofuRemoteBackend.drawio.png)

1. The user assumes an Amazon IAM role with the sufficient permissions provided above.
2. The user deploys the OpenTofu Amazon S3 remote backend using the assumed Amazon IAM role
3. The user deploys infrastructure using OpenTofu which stores the remote state on Amazon S3.

## Outputs

After running the script, it will output the names of:

- The Amazon S3 bucket for the OpenTofu backend.
- The AWS DynamoDB table for the OpenTofu backend.

## Security

The CloudFormation template is designed with security in mind:

- Encryption is enforced on the Amazon S3 bucket using an Amazon KMS Key.
- Public access is blocked for all Amazon S3 buckets.
- Deletion policies are set to retain to prevent data loss.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.

## Contact

- juligrue@amazon.ch


# Dependencies and Licenses

This project is licensed under the MIT License - see the `LICENSE` file for details.

## OpenTofu Project

This project uses OpenTofu as a key dependency. OpenTofu is an open-source software project licensed under the Mozilla Public License 2.0 (MPL-2.0).

### OpenTofu License Information:

* License: Mozilla Public License 2.0 (MPL-2.0)
* OpenTofu Project Link: https://github.com/opentofu/opentofu
* MPL-2.0 License Details: [Mozilla Public License v2.0](/Mozilla%20Public%20License%202.0)

We adhere to the terms and conditions of the MPL-2.0 license for the OpenTofu component within our project. Please refer to the provided links for more information on OpenTofu and its license.
