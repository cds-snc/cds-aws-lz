#!/bin/bash

POLICY_NAME="AWSControlTowerExecution"

read -r -d '' INPUT <<EOF

{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::659087519042:root"
      },
    "Action": "sts:AssumeRole",
    "Condition": {}
  }]
}

EOF

echo "Creating role $POLICY_NAME"
aws iam create-role --role-name "$POLICY_NAME" \
  --assume-role-policy-document "$(jq <<< "$INPUT")"

echo "Attach AdministratorAccess policy to $POLICY_NAME"
aws iam attach-role-policy --role-name "$POLICY_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess 