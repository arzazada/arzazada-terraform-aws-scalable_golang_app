#
#resource "aws_iam_role" "instance_role" {
#  name = "demo-app-instance-role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Action = "sts:AssumeRole",
#        Effect = "Allow",
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        }
#      }
#
#    ]
#  })
#}
#
#resource "aws_iam_policy" "insace_policy" {
#  name        = "demo-app-ssm-policy"
#  description = "IAM policy to allow SSM access"
#
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Sid      = "AllowSSM",
#        Effect   = "Allow",
#        Action   = ["ssm:GetParameter"],
#        Resource = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.project_name}/*"],
#      },
#      {
#        Sid      = "AllowS3",
#        Effect   = "Allow",
#        Action   = ["s3:Get*", "s3:List*"],
#        Resource = ["*"],
#      },
#    ],
#  })
#}
#
#resource "aws_iam_instance_profile" "iam_profile" {
#  name = "test_profile"
#  role = aws_iam_role.instance_role.name
#}
#
#resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
#  policy_arn = aws_iam_policy.insace_policy.arn
#  role       = aws_iam_role.instance_role.name
#}
#
#resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_attachment" {
#  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#  role       = aws_iam_role.instance_role.name
#}
#
#resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core_attachment" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#  role       = aws_iam_role.instance_role.name
#}
#
#
## for add config ssm parameter store
#resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_admin_policy_attachment" {
#  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
#  role       = aws_iam_role.instance_role.name
#}
