#!/bin/bash

if [ $# -eq 0 ]; then
  echo "An organizational unit (OU) must be provided as an argument"
  exit 1
fi
read -r -d '' INPUT <<EOF
  {
    "include" : [
      {
        "type": "ous",
        "target_value": ["$@"]
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
