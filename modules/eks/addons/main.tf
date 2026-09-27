locals {
  ebs_csi_enabled = try(var.addons.ebs_csi.enabled, true)
  ebs_csi_version = try(var.addons.ebs_csi.version, "v1.66.0-eksbuild.1")
  oidc_host       = replace(var.oidc_issuer_url, "https://", "")
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = local.ebs_csi_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = local.ebs_csi_enabled ? 1 : 0

  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ebs-csi-driver"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = local.ebs_csi_enabled ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  count = local.ebs_csi_enabled ? 1 : 0

  cluster_name  = var.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = local.ebs_csi_version

  service_account_role_arn = aws_iam_role.ebs_csi[0].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ebs-csi"
  })
}
