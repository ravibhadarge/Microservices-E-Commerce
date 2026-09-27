resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  create_namespace = false

  wait    = true
  timeout = 900

  values = [
    yamlencode({
      settings = {
        clusterName     = var.cluster_name
        clusterEndpoint = var.cluster_endpoint
      }

      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.controller.arn
        }
      }

      controller = {
        resources = {
          requests = {
            cpu    = "200m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.controller,
    aws_eks_access_entry.node
  ]
}

# ---------------------------------------------------------
# Karpenter EC2NodeClass
# ---------------------------------------------------------

resource "kubernetes_manifest" "ec2nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"

    metadata = {
      name = "default"
    }

    spec = {
      amiSelectorTerms = [
        {
          alias = "al2023@latest"
        }
      ]

      role = aws_iam_role.node.name

      subnetSelectorTerms = [
        for subnet_id in var.subnet_ids : {
          id = subnet_id
        }
      ]

      securityGroupSelectorTerms = [
        {
          id = var.cluster_security_group_id
        }
      ]

      tags = merge(var.tags, {
        Name = "${var.cluster_name}-karpenter-node"
      })
    }
  }

  depends_on = [
    helm_release.karpenter,
    aws_eks_access_entry.node
  ]
}

# ---------------------------------------------------------
# Karpenter NodePool
# ---------------------------------------------------------

resource "kubernetes_manifest" "nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name = "default"
    }

    spec = {
      template = {
        metadata = {
          labels = {
            "workload" = "karpenter"
          }
        }

        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }

          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "node.kubernetes.io/instance-generation"
              operator = "Gt"
              values   = ["5"]
            }
          ]
        }
      }

      limits = {
        cpu = "20"
      }

      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "1m"
      }
    }
  }

  depends_on = [
    kubernetes_manifest.ec2nodeclass
  ]
}
