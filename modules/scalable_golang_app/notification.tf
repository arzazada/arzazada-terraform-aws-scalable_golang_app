###  SNS

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [join("", aws_sns_topic.notif.*.arn)]
  }
}

resource "aws_sns_topic" "notif" {
  name                             = "codepipeline-notifications"
  lambda_failure_feedback_role_arn = aws_iam_role.delivery_feedback_role.arn
  lambda_success_feedback_role_arn = aws_iam_role.delivery_feedback_role.arn
}

resource "aws_sns_topic_policy" "topic_policy" {
  arn    = join("", aws_sns_topic.notif.*.arn)
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "topic_subscription" {

  topic_arn = join("", aws_sns_topic.notif.*.arn)
  protocol  = "lambda"
  endpoint  = join("", aws_lambda_function.status_lambda.*.arn)
}

# Feedback role
data "aws_iam_policy_document" "feedback_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delivery_feedback_role" {
  name               = "SNSFeedbackRole"
  assume_role_policy = data.aws_iam_policy_document.feedback_assume_role_policy.json

  inline_policy {
    name = "SNSFeedbackPolicy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:PutMetricFilter",
            "logs:PutRetentionPolicy"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
    })
  }
}

#resource "aws_sns_topic" "notif" {
#  name                             = "${var.project_name}-cp-notification"
#  lambda_failure_feedback_role_arn = aws_iam_role.delivery_feedback_role.arn
#  lambda_success_feedback_role_arn = aws_iam_role.delivery_feedback_role.arn
#}
#
#resource "aws_sns_topic_policy" "topic_policy22" {
#  arn    = aws_sns_topic.notif.arn
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Action = ["SNS:Publish"],
#        Effect = "Allow",
#        Principals = {
#          Service = "codestar-notifications.amazonaws.com"
#        },
#        Resources = [aws_sns_topic.notif.arn]
#      }
#    ]
#  })
#}
#
#resource "aws_sns_topic_subscription" "topic_subscription" {
#
#  topic_arn = aws_sns_topic.notif.arn
#  protocol  = "lambda"
#  endpoint  = aws_lambda_function.status_lambda.arn
#}
#
#data "aws_iam_policy_document" "feedback_assume_role_policy" {
#  statement {
#    actions = ["sts:AssumeRole"]
#    principals {
#      type        = "Service"
#      identifiers = ["sns.amazonaws.com"]
#    }
#  }
#}
#
#resource "aws_iam_role" "delivery_feedback_role" {
#  name               = "SNSFeedbackRole"
#  assume_role_policy = data.aws_iam_policy_document.feedback_assume_role_policy.json
#
#  inline_policy {
#    name = "SNSFeedbackPolicy"
#
#    policy = jsonencode({
#      "Version" : "2012-10-17",
#      "Statement" : [
#        {
#          "Effect" : "Allow",
#          "Action" : [
#            "logs:CreateLogGroup",
#            "logs:CreateLogStream",
#            "logs:PutLogEvents",
#            "logs:PutMetricFilter",
#            "logs:PutRetentionPolicy"
#          ],
#          "Resource" : [
#            "*"
#          ]
#        }
#      ]
#    })
#  }
#}
##### CodeStar

# https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api
resource "aws_codestarnotifications_notification_rule" "status" {
  detail_type = "FULL"
  name        = "github"
  resource    = aws_codepipeline.scalable_golang_app_pipeline.arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-superseded",
    "codepipeline-pipeline-pipeline-execution-succeeded"
  ]

  target {
    address = aws_sns_topic.notif.arn
  }
}

#   LAMBDA

data "archive_file" "status_lambda_file" {
  type             = "zip"
  source_file      = "${path.root}/files/lambdas/pipeline-status-lambda/main"
  output_path      = "/tmp/pipeline-status-lambda.zip"
  output_file_mode = "0777"
}

resource "aws_lambda_function" "status_lambda" {
  filename         = data.archive_file.status_lambda_file.output_path
  source_code_hash = data.archive_file.status_lambda_file.output_base64sha256
  function_name    = "pipeline-status"
  handler          = "main"
  runtime          = "go1.x"
  role             = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.notif.arn
}

resource "aws_iam_role" "lambda_role" {
  name               = "codepipeline-notification-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["sts:AssumeRole"],
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name   = "codepipeline-notification-lambda-policy"
  role   = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = ["*"]
      },
      {
        Action   = ["ssm:GetParameter"],
        Effect   = "Allow",
        Resource = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.project_name}/*"]
      },
      {
        Action   = ["codepipeline:GetPipelineExecution", "codepipeline:ListActionExecutions"],
        Effect   = "Allow",
        Resource = [aws_codepipeline.scalable_golang_app_pipeline.arn]
      }
    ]
  })
}





#
#resource "aws_iam_role" "lambda_role" {
#  name               = "codepipeline-notification-lambda-role"
#  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
#}
#
#data "aws_iam_policy_document" "assume_role_lambda" {
#  statement {
#    actions = ["sts:AssumeRole"]
#    principals {
#      type        = "Service"
#      identifiers = ["lambda.amazonaws.com"]
#    }
#  }
#}
#
#resource "aws_iam_policy" "lambda_policy" {
#  name   = "codepipeline-notification-lambda-policy"
#  policy = data.aws_iam_policy_document.lambda_policy.json
#}
#
#data "aws_iam_policy_document" "lambda_policy" {
#  statement {
#    actions = [
#      "logs:CreateLogGroup",
#      "logs:CreateLogStream",
#      "logs:PutLogEvents"
#    ]
#    effect    = "Allow"
#    resources = ["*"]
#  }
#
#  statement {
#    actions   = ["ssm:GetParameter"]
#    effect    = "Allow"
#    resources = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.project_name}/GITHUB_TOKEN"]
#  }
#
#  statement {
#    actions = [
#      "codepipeline:GetPipelineExecution",
#      "codepipeline:ListActionExecutions"
#    ]
#    effect    = "Allow"
#    resources = aws_codepipeline.scalable_golang_app_pipeline.arn
#  }
#
#}
#
#resource "aws_iam_role_policy_attachment" "lambda_role_attached_policy" {
#  role       = aws_iam_role.lambda_role.name
#  policy_arn = aws_iam_policy.lambda_policy.arn
#}



