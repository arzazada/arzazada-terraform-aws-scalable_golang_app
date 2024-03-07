resource "aws_launch_template" "launch_template" {

  name                   = "Scalable_Golang_App"
  image_id               = var.my_custom_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  user_data              = base64encode(file("${path.cwd}/files/userdata/golang_node.yaml.tpl"))

  iam_instance_profile {
    name = aws_iam_instance_profile.iam_profile.name
  }
}

resource "aws_autoscaling_group" "sga_asg" {
  name             = "Scalable_Golang_App"
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier       = local.private_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.sga_target_group.arn]

  # Optional parameters

  #  instance_refresh {      TODO: add notification
  #    strategy = "Rolling"
  #    preferences {
  #      min_healthy_percentage = 50
  #    }
  #    triggers = ["tag"]
  #  }
  #
  #
  #  instance_maintenance_policy {
  #    min_healthy_percentage = 90
  #    max_healthy_percentage = 120
  #  }
  #

  #  notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
  #  role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  #}
}


resource "aws_iam_role" "instance_role" {
  name = "demo-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }

    ]
  })
}

resource "aws_iam_policy" "insace_policy" {
  name        = "demo-app-ssm-policy"
  description = "IAM policy to allow SSM access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowSSM",
        Effect   = "Allow",
        Action   = ["ssm:GetParameter"],
        Resource = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.project_name}/*"],
      },
      {
        Sid      = "AllowS3",
        Effect   = "Allow",
        Action   = ["s3:Get*", "s3:List*"],
        Resource = ["*"],
      },
    ],
  })
}

resource "aws_iam_instance_profile" "iam_profile" {
  name = "test_profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  policy_arn = aws_iam_policy.insace_policy.arn
  role       = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance_role.name
}

# for add config ssm parameter store
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_admin_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
  role       = aws_iam_role.instance_role.name
}

