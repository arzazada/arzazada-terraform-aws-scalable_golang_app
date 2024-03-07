resource "aws_ssm_parameter" "APP_CLIENT_ID" {
  name        = "/demo-app/APP_CLIENT_ID"
  description = "The parameter description"
  type        = "SecureString"
  value       = aws_cognito_user_pool_client.main.id

  tags = local.default_tags
}


resource "aws_ssm_parameter" "APP_CLIENT_SECRET" {
  name        = "/demo-app/APP_CLIENT_SECRET"
  description = "The parameter description"
  type        = "SecureString"
  value       = aws_cognito_user_pool_client.main.client_secret

  tags = local.default_tags
}

resource "aws_ssm_parameter" "DB_ENGINE" {
  name        = "/demo-app/DB_ENGINE"
  description = "The parameter description"
  type        = "SecureString"
  value       = "postgres"

  tags = local.default_tags
}

resource "aws_ssm_parameter" "DB_HOST" {
  name        = "/demo-app/DB_HOST"
  description = "The parameter description"
  type        = "SecureString"
  value       = aws_db_instance.sga_project_db.endpoint

  tags = local.default_tags
}

resource "aws_ssm_parameter" "DB_NAME" {
  name        = "/demo-app/DB_NAME"
  description = "The parameter description"
  type        = "SecureString"
  value       = aws_db_instance.sga_project_db.db_name

  tags = local.default_tags
}

resource "aws_ssm_parameter" "DB_USERNAME" {
  name        = "/demo-app/DB_USERNAME"
  description = "The parameter description"
  type        = "SecureString"
  value       = var.db_user_name

  tags = local.default_tags
}

resource "aws_ssm_parameter" "DB_PASSWORD" {
  name        = "/demo-app/DB_PASSWORD"
  description = "The parameter description"
  type        = "SecureString"
  value       = var.db_user_password

  tags = local.default_tags
}

resource "aws_ssm_parameter" "SESSIION_ENCRYPTION_SECRET" {
  name        = "/demo-app/SESSION_ENCRYPTION_SECRET"
  description = "The parameter description"
  type        = "SecureString"
  value       = "z4PhNX7vuL3xVChQ1m2AB9Yg5AULVxXcg/SpIdNs6c5H0NE8XYXysP+DGNKHfuwvY7kxvUdBeoGlODJ6+SfaPg=="

  tags = local.default_tags
}

resource "aws_ssm_parameter" "AmazonCloudWatch-linux" {
  name        = "AmazonCloudWatch-linux"
  description = "The parameter description"
  type        = "SecureString"
  value       = templatefile("${path.cwd}/files/AmazonCloudWatch-linux.json.tpl", {
    project_name = var.project_name
    appdir       = local.appdir
  })

  tags = local.default_tags
}

resource "aws_ssm_parameter" "demo-app-systemfile" {
  name        = "/${var.project_name}/systemdfile"
  description = "The parameter description"
  type        = "SecureString"
  value       = templatefile("${path.cwd}/files/systemfile.txt.tpl", {
    appdir = local.appdir
  })

  tags = local.default_tags
}

resource "aws_ssm_parameter" "github_token" {
  name        = "/demo-app/GITHUB_TOKEN"
  description = "The parameter description"
  type        = "SecureString"
  value       = var.github_token

  tags = local.default_tags
}
