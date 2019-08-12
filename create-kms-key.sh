#!/bin/sh

key_id=`aws kms create-key | jq -r '.KeyMetadata.KeyId'`
echo "AWS KMS KeyId: $key_id"

echo -n "AWS KMS Master key alias: "
read key_alias

aws kms create-alias --alias-name "alias/$key_alias" --target-key-id $key_id

echo -e "\nexisiting IAM Roles:"
aws iam list-roles | jq -r '.Roles[] | .RoleName'

echo
echo -n "IAM Role name for KMS: "
read role_name

aws_id=`aws sts get-caller-identity | jq -r '.Account' `
echo "AWS Account ID: $aws_id"

policy_file='kms-key-policy.json'

cat <<EOF >$policy_file
{
  "Version": "2012-10-17",
  "Id": "key-consolepolicy-3",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${aws_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${aws_id}:role/$role_name"
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${aws_id}:role/$role_name"
        ]
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": true
        }
      }
    }
  ]
}
EOF
dos2unix $policy_file
echo "AWS KMS KeyId: $key_id"
aws kms put-key-policy --key-id $key_id \
                       --policy-name default \
                       --policy file://$policy_file
