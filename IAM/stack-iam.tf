resource "aws_iam_user" "user" {
  name          = var.USERNAME
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user_login_profile" "log-prof" {
  user    = aws_iam_user.user.name
  pgp_key = "keybase:stack_simi"
}

output "password" {
  value = aws_iam_user_login_profile.log-prof.encrypted_password
}

resource "aws_iam_group" "group" {
  name = "stack-group"
}

resource "aws_iam_policy" "policy" {
  name        = "stack-admin"
  description = "A policy that gives admin access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "stack-attach" {
  name       = "stack-attachment"
  groups     = [aws_iam_group.group.name]
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_group_membership" "team" {
  name = "stack-group-membership"

  users = [
    aws_iam_user.user.name,
  ]

  group = aws_iam_group.group.name
}

