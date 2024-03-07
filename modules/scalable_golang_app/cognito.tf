resource "aws_cognito_user_pool" "user_pool" {
  name                     = "${var.project_name}-user-pool"
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  password_policy {
    minimum_length                   = 7
    temporary_password_validity_days = 7
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name            = "${var.project_name}-user-pool-client"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = true

  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH"]
  callback_urls                        = ["https://${var.project_name}.${var.domain}/callback"]
  default_redirect_uri                 = "https://${var.project_name}.${var.domain}/callback"
  allowed_oauth_flows_user_pool_client = true
}

