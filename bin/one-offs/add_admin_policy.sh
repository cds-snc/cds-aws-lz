#!/bin/bash

ACCOUNT_LIST="$(aws configure list-profiles)"

while IFS= read -r AWS_PROFILE
do

  if [[ "$AWS_PROFILE" != *".AWSAdministratorAccess"* ]]; then
    continue
  fi

    echo "Onboard account: $AWS_PROFILE"
    ASSUMED_ROLE="$(aws --profile "$AWS_PROFILE" sts get-caller-identity | jq -r '.Arn')"

    echo "Assumed role via SSO: $ASSUMED_ROLE"

    echo "Attaching AdministratorAccess to group admins"
    aws --profile "$AWS_PROFILE" iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --group-name admins

    sleep 1

done < <(printf '%s\n' "$ACCOUNT_LIST")
