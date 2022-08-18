#!/bin/bash


FUNCTION_NAMES=$(aws lambda list-functions | jq -r ".Functions[].FunctionName")


for FUNCTION_NAME in $FUNCTION_NAMES; do
  POLICY=$(aws lambda get-policy --function-name "$FUNCTION_NAME")
  if [[ "$POLICY" =~ PrincipalOrgID ]]; then
    echo "Policy for $FUNCTION_NAME contains PrincipalOrgID"
  fi
done