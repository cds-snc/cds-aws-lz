#!/bin/bash

ACCOUNT_ID=$1

if [ -z "$ACCOUNT_ID" ]; then
  echo "Usage: invoke_account.sh <account_id>"
  exit 1
fi



read -r -d '' INPUT <<EOF
{
  "include" : [
    {
      "type": "accounts",
      "target_value": ["$ACCOUNT_ID"]

    }
  ]
}
EOF

TIMESTAMP=$(date +%s)


aws stepfunctions start-execution \
  --region "ca-central-1" \
  --state-machine-arn "arn:aws:states:ca-central-1:137554749751:stateMachine:aft-invoke-customizations" \
  --name  "$TIMESTAMP-invoke-customizations-all" \
  --input "$(jq <<< "$INPUT")"
