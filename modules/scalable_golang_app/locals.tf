data "aws_availability_zones" "az" {
  state = "available"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  private_subnet_ids = aws_subnet.private_subnet[*].id
  public_subnet_ids  = aws_subnet.public_subnet[*].id
  appdir             = "/etc/${var.project_name}"
  az_names           = data.aws_availability_zones.az.names
  account_id         = data.aws_caller_identity.current.id
  region             = data.aws_region.current.name

  default_tags = {
    Owner       = "Devops"
    Managed-by  = "Terraform"
    Environment = var.env
  }
}




