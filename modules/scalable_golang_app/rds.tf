resource "aws_db_instance" "sga_project_db" {
  allocated_storage      = 10
  db_name                = "awsgodemo"
  engine                 = "postgres"
  engine_version         = "12.14"
  instance_class         = "db.t3.micro"
  username               = var.db_user_name
  password               = var.db_user_password
  parameter_group_name   = "default.postgres12"
  skip_final_snapshot    = true
  multi_az               = true
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main"
  subnet_ids = [local.private_subnet_ids[0], local.private_subnet_ids[1]]

  tags = {
    Name = "DB subnet group"
  }
}