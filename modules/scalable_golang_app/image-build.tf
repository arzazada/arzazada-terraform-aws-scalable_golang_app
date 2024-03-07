data "aws_ami" "base_ami" {
  most_recent = true
  owners      = var.ami_owners
  name_regex  = var.ami_regex
}

# IAM Role
resource "aws_iam_role" "awsserviceroleforimagebuilder" {
  name = "EC2ImageBuilderRole"
  tags = local.default_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "imagebuilder" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
  role       = aws_iam_role.awsserviceroleforimagebuilder.name
}
resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.awsserviceroleforimagebuilder.name
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "EC2InstanceProfileImageBuilder"
  role = aws_iam_role.awsserviceroleforimagebuilder.name
}

# EC2 Image Builder Image Pipeline
resource "aws_imagebuilder_image_pipeline" "imagebuilder_image_pipeline" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.imagebuilder_image_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.imagebuilder_infrastructure_configuration.arn

  schedule {
    schedule_expression = "cron(0 8 1 * ? **)"
  }
  name = "My-Image-Pipeline"
  tags = local.default_tags
}

# EC2 Image Builder Image Recipe
resource "aws_imagebuilder_image_recipe" "imagebuilder_image_recipe" {

  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/amazon-cloudwatch-agent-linux/x.x.x" # 1.0.0"
  }

  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/update-linux/x.x.x" #1.0.0"
  }

  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/aws-cli-version-2-linux/x.x.x"
  }

  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/simple-boot-test-linux/x.x.x" #1.0.0"
  }

  component {
    component_arn = "arn:aws:imagebuilder:${local.region}:aws:component/aws-codedeploy-agent-linux/1.1.1"
  }

  name         = "My_Custom_Image"
  parent_image = data.aws_ami.base_ami.id
  version      = "1.0.0"
}

# EC2 Image Builder Infrastructure Configuration
resource "aws_imagebuilder_infrastructure_configuration" "imagebuilder_infrastructure_configuration" {
  instance_profile_name         = aws_iam_instance_profile.iam_instance_profile.name
  instance_types                = var.instance_types
  name                          = "MY-infrastructure-configuration"
  terminate_instance_on_failure = true
  resource_tags                 = local.default_tags
  tags                          = local.default_tags
}
