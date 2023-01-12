#!/bin/bash

if ! lpass status; then
  echo "Error: Must be logged in lpass"
  exit 1
fi

NOW=$(date)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
USERS=$(aws iam list-users | jq .Users | jq '.[] | .UserName')

echo "Updating passwords for account id: $ACCOUNT_ID"

# Check if ops1 and ops2 users are in the account
if [[ ! "$USERS" =~ "ops1" && ! "$USERS" =~ "ops2" ]]; then
  echo "Requires users 'ops1' and 'ops2' to be present in the account."
  exit 1
fi

OPS1PWORD=$(aws secretsmanager get-random-password --region ca-central-1 | jq -r '.RandomPassword')
aws iam update-login-profile --user-name ops1 --password "$OPS1PWORD"

OPS2PWORD=$(aws secretsmanager get-random-password --region ca-central-1 | jq -r '.RandomPassword')
aws iam update-login-profile --user-name ops2 --password "$OPS2PWORD"

lpass add --notes "Shared-SRE - AWS Cloud credentials/Control Tower/$ACCOUNT_ID - Rotated" --non-interactive --sync=now <<EOF
~~~~~~
Updated on: $NOW

uname: ops1
pword: $OPS1PWORD

uname: ops2
pword: $OPS2PWORD
~~~~~~
EOF
