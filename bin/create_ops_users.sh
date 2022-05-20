#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
aws iam create-group --group-name admins

aws iam create-user --user-name ops1
aws iam add-user-to-group --user-name ops1 --group-name admins
OPS1PWORD=$(aws secretsmanager get-random-password | jq -r '.RandomPassword')
aws iam create-login-profile --user-name ops1 --password "$OPS1PWORD"

aws iam create-user --user-name ops2
aws iam add-user-to-group --user-name ops2 --group-name admins
OPS2PWORD=$(aws secretsmanager get-random-password | jq -r '.RandomPassword')
aws iam create-login-profile --user-name ops2 --password "$OPS2PWORD"

lpass add --notes "Shared-SRE - AWS Cloud credentials/$ACCOUNT_ID" --non-interactive --sync=now <<EOF

uname: ops1
pword: $OPS1PWORD

uname: ops2
pword: $OPS2PWORD

EOF