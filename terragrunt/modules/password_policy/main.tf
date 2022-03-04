# This password policy should adhere to the GoC Recommendation for passwords
# Source: https://www.canada.ca/en/government/system/digital-government/online-security-privacy/password-guidance.html

resource "aws_iam_account_password_policy" "goc" { 
  minimum_password_length = 12
  require_symbols = true
  require_numbers = true
  require_lowercase_characters = true
  require_uppercase_characters = true
  allow_users_to_change_password = true
  expire_passwords = false
  hard_expiry = false
  password_reuse_prevention = 24
}