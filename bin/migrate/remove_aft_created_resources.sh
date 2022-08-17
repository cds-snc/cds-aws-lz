#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "Removing resources in account $ACCOUNT_ID"
echo "Type REMOVE to confirm"
read -r RESPONSE

if [ "$RESPONSE" == "REMOVE" ]; then
  echo "Removing resources in account $ACCOUNT_ID"

  echo "Removing Github OIDC Provider"
  aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

  echo "Removing secopsAssetInventorySecurityAuditRole"
  aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/SecurityAudit --role-name secopsAssetInventorySecurityAuditRole
  aws iam delete-role --role-name secopsAssetInventorySecurityAuditRole

  echo "Removing ConfigTerraformAdminExecutionRole"
  aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name ConfigTerraformAdminExecutionRole
  aws iam delete-role --role-name ConfigTerraformAdminExecutionRole

  echo "Removing CbsSatelliteReplicateToLogArchive"
  aws iam detach-role-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/CbsSatelliteReplicateToLogArchive" --role-name CbsSatelliteReplicateToLogArchive
  aws iam delete-role --role-name CbsSatelliteReplicateToLogArchive
  aws iam delete-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/CbsSatelliteReplicateToLogArchive"

else
  echo "Aborting"
fi