import json
import boto3

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

orgs = boto3.client('organizations')
s3 = boto3.client('s3')

def lambda_handler(event: dict, context: LambdaContext):
    logger.info("Getting account tags")
    accounts = []
    accounts_result = orgs.list_accounts();
    accounts += accounts_result['Accounts']
    while 'NextToken' in accounts_result:
        logger.info("Paginating accounts...")
        accounts_result = orgs.list_accounts(NextToken=accounts_result['NextToken'])
        accounts += accounts_result['Accounts']
    
    # Iterate over the accounts and get the tags and then add them to the account in the list
    logger.info("Getting account tags")
    for account in accounts:

        account_tags = orgs.list_tags_for_resource(ResourceId=account["Id"])

        # Convert the tags from {'Key': 'Name', 'Value': 'Dev'} to {'Name': 'Dev'}
        account_tags['Tags'] = {tag['Key']: tag['Value'] for tag in account_tags['Tags']}
        
        account['Tags'] = account_tags['Tags']

    # Get a set of all possible tag keys
    tag_keys = set()
    for account in accounts:
        tag_keys.update(account['Tags'].keys())
    logger.info(f"Found tag keys: {tag_keys}")

    logger.info(f"Adding empty strings for missing tags")
    # Add empty strings for all the tags that are not present in the account
    for account in accounts:
        for tag_key in tag_keys:
            if tag_key not in account['Tags']:
                account['Tags'][tag_key] = ""

    # Convert the tags into the format tag_key_name: tag_value and add them to the base object
    logger.info(f"Converting tags to tag_key_name: tag_value")
    for account in accounts:
        for tag_key, tag_value in account['Tags'].items():
            account[f"tag_{tag_key}"] = tag_value
        del account['Tags']

    # .write json to string and add a newline between each record 
    logger.info(f"Writing account tags to json")
    accounts = json.dumps(accounts, default=str)
    accounts = accounts.replace('},', '},\n')
    accounts = accounts.replace('[{', '[\n{')
    
    print(f"Accounts: {accounts}")
    # save accounts to an s3 bucket 
    logger.info(f"Saving account tags to s3")
    s3.put_object(Bucket='5bf89a78-1503-4e02-9621-3ac658f558fb', Key='account_tags.json', Body=accounts)

    return {
        'statusCode': 200,
        'body': json.dumps(accounts, default=str)
    }


lambda_handler(None,None)