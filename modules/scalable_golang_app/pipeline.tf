###  CodeBuild
resource "aws_codebuild_project" "scalable_golang_app_build" {
  name           = "Scalable_Golang_App_Build"
  build_timeout  = 5
  queued_timeout = 5

  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0" # Ubuntu
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "GOOS"
      value = "linux"

    }
    #    environment_variable {
    #      name  = "GOARCH"
    #      value = "amd64"
    #    }
    #    environment_variable {
    #      name  = "GO_VERSION"
    #      value = "1.13"
    #    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "sga-build-logs"
      stream_name = "sga-build"
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }


  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.cwd}/files/buildspec.yml")
  }

  tags = local.default_tags

}

###  CodeDeploy
resource "aws_codedeploy_app" "scalable_golang_app" {
  name             = "Scalable_Golang_App"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "sga_deployment_group" {
  app_name               = aws_codedeploy_app.scalable_golang_app.name
  deployment_group_name  = "Scalable_Golang_App_Deployment_Group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  autoscaling_groups     = [aws_autoscaling_group.sga_asg.name]

  deployment_style {
    deployment_type = "IN_PLACE"
  }

}


##### CodeStar Connection

#resource "aws_iam_service_linked_role" "codestar" {
#  aws_service_name = "codestar-notifications.amazonaws.com"
#}

resource "aws_codestarconnections_connection" "github-connect-all-project" {
  name          = "github-connect-all-project"
  provider_type = "GitHub"
}


###  CodePipeline

resource "aws_s3_bucket" "scalable_golang_app_bucket" {
  bucket = "scalable-golang-app-bucket"
}

resource "aws_codepipeline" "scalable_golang_app_pipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.scalable_golang_app_bucket.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github-connect-all-project.arn
        FullRepositoryId = "arzazada/aws-go-demo"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.scalable_golang_app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.scalable_golang_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.sga_deployment_group.deployment_group_name
      }
    }
  }
}


#################### Pipeline Policies  #######################

# Code Pipeline Policy
resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
#          Type        = "Service",
#          Identifiers = ["codepipeline.amazonaws.com"]
        },
        Action = ["sts:AssumeRole"]
      }
    ]
  })
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.scalable_golang_app_bucket.arn,
      "${aws_s3_bucket.scalable_golang_app_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeployment",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetApplicationRevision",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github-connect-all-project.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


# Code Build Policy
data "aws_iam_policy_document" "assume_role_cb" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_cb.json
}


data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.scalable_golang_app_bucket.arn,
      "${aws_s3_bucket.scalable_golang_app_bucket.arn}/*",
    ]
  }

}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild_policy"
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

## Code Deploy Policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "codedeploy_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.name
}


