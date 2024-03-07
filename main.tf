module "scalable_golang_app" {
  source           = "./modules/scalable_golang_app"
  vpc_cidr         = "10.0.0.0/16"
  project_name     = "demo-app"
  env              = "prod"
  az_count         = 2
  instance_type    = "t2.micro"
  instance_types   = ["t2.micro"]
  my_custom_ami    = "ami-0d4a9a93358651ae6"
  volume_size      = 10
  max_size         = 3
  min_size         = 2
  desired_capacity = 2
  domain           = var.domain
  db_user_password = var.db_user_password
  db_user_name     = var.db_user_name
  github_token     = var.github_token
}

