#!/bin/bash


read -r -d '' INPUT <<EOF
{
  "include" : [
    {
      "type": "accounts",
      "target_value": ["034163289675"]

    }
  ],
  "exclude" : [
    {
      "type": "ous",
      "target_value": ["production"]
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
