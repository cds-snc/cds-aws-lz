import unittest
from unittest.mock import patch, MagicMock
from main import handler

TARGET_BUCKET = "TARGET_BUCKET"
ACCOUNT_TAGS_KEY = "operations/aws/organization/account-tags.json"


class TestLambdaHandler(unittest.TestCase):
    def setUp(self):
        self.event = {}
        self.context = MagicMock()

    @patch("main.orgs.list_accounts")
    @patch("main.orgs.list_tags_for_resource")
    @patch("main.s3.put_object")
    @patch("main.TARGET_BUCKET", TARGET_BUCKET)
    def test_lambda_handler(
        self, mock_s3_put, mock_orgs_list_tags, mock_orgs_list_accounts
    ):
        mock_orgs_list_accounts.return_value = {
            "Accounts": [{"Id": "123"}],
        }
        mock_orgs_list_tags.return_value = {"Tags": [{"Key": "Name", "Value": "Dev"}]}

        response = handler(self.event, self.context)

        mock_orgs_list_accounts.assert_called()
        mock_orgs_list_tags.assert_called_with(ResourceId="123")
        mock_s3_put.assert_called_with(
            Bucket=TARGET_BUCKET,
            Key=ACCOUNT_TAGS_KEY,
            Body="""[
{"id": "123","tag_name": "Dev"}
]""",
        )

        self.assertEqual(response, {"statusCode": 200})

    @patch("main.orgs.list_accounts")
    @patch("main.orgs.list_tags_for_resource")
    @patch("main.s3.put_object")
    @patch("main.TARGET_BUCKET", TARGET_BUCKET)
    def test_lambda_handler_pagination(
        self, mock_s3_put, mock_orgs_list_tags, mock_orgs_list_accounts
    ):
        mock_orgs_list_accounts.side_effect = [
            {"Accounts": [{"Id": "123"}], "NextToken": "token"},
            {"Accounts": [{"Id": "456"}]},
        ]
        mock_orgs_list_tags.side_effect = [
            {"Tags": [{"Key": "Name", "Value": "Dev"}]},
            {"Tags": [{"Key": "Name", "Value": "Prod"}]},
        ]

        handler(self.event, self.context)

        mock_orgs_list_accounts.assert_any_call(NextToken="token")
        mock_orgs_list_tags.assert_any_call(ResourceId="123")
        mock_orgs_list_tags.assert_any_call(ResourceId="456")
        mock_s3_put.assert_called_with(
            Bucket=TARGET_BUCKET,
            Key=ACCOUNT_TAGS_KEY,
            Body="""[
{"id": "123","tag_name": "Dev"},
{"id": "456","tag_name": "Prod"}
]""",
        )
