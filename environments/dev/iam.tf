
  statement {
    sid    = "SSMRead"
    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::parameter/aws/service/*"
    ]
  }

  statement {
    sid    = "InstanceProfileManagement"
    effect = "Allow"

    actions = [
      "iam:CreateInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
    ]
  }


  statement {
    sid    = "SSMRead"
    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::parameter/aws/service/*"
    ]
  }

  statement {
    sid    = "InstanceProfileManagement"
    effect = "Allow"

    actions = [
      "iam:CreateInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
    ]
  }

}
