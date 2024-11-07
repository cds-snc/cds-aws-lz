"""
Get the tags for all accounts in the organization and save them to an s3 bucket.
This is then used to enrich the billing data with the account tags to allow
for business unit filtering.
"""
import json
import logging
import os

import boto3

orgs = boto3.client("organizations")
s3 = boto3.client("s3")

TARGET_BUCKET = os.getenv("TARGET_BUCKET")


def handler(event, context):
    """
    Get the tags for all accounts in the organization and save them to an s3 bucket
    """
    logging.info("Getting account tags")
    accounts = []
    accounts_result = orgs.list_accounts()
    accounts += accounts_result["Accounts"]
    while "NextToken" in accounts_result:
        logging.info("Paginating accounts...")
        accounts_result = orgs.list_accounts(NextToken=accounts_result["NextToken"])
        accounts += accounts_result["Accounts"]

    # Iterate over the accounts and get the tags and then add them to the account in the list
    logging.info("Getting account tags")
    for account in accounts:
        account_tags = orgs.list_tags_for_resource(ResourceId=account["Id"])

        # Convert the tags from {'Key': 'Name', 'Value': 'Dev'} to {'Name': 'Dev'}
        account_tags["Tags"] = {
            tag["Key"]: tag["Value"] for tag in account_tags["Tags"]
        }
        account["Tags"] = account_tags["Tags"]

    # Get a set of all possible tag keys
    tag_keys = set()
    for account in accounts:
        tag_keys.update(account["Tags"].keys())
    logging.info(f"Found tag keys: {tag_keys}")

    # Add empty strings for all the tags that are not present in the account
    logging.info("Adding empty strings for missing tags")
    for account in accounts:
        for tag_key in tag_keys:
            if tag_key not in account["Tags"]:
                account["Tags"][tag_key] = ""

    # Convert the tags into the format tag_key_name: tag_value and add them to the base object
    logging.info("Converting tags to tag_key_name: tag_value")
    for account in accounts:
        for tag_key, tag_value in account["Tags"].items():
            account[f"tag_{tag_key}"] = tag_value
        del account["Tags"]

    # .write json to string and add a newline between each record
    logging.info("Writing account tags to json")
    accounts = json.dumps(accounts, default=str)
    accounts = accounts.replace("}, ", "},\n")
    accounts = accounts.replace("[{", "[\n{")
    logging.info(f"Accounts: {accounts}")

    # save accounts to an s3 bucket
    logging.info("Saving account tags to s3")
    s3.put_object(Bucket=TARGET_BUCKET, Key="operations/aws/organization/account-tags.json", Body=accounts)

    return {"statusCode": 200}
