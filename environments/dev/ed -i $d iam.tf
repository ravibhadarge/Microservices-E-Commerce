{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "ec2:DescribeVolumes",
                        "ec2:DescribeTags",
                        "ec2:DescribeSubnets",
                        "ec2:DescribeSpotPriceHistory",
                        "ec2:DescribeSecurityGroups",
                        "ec2:DescribeLaunchTemplates",
                        "ec2:DescribeInstances",
                        "ec2:DescribeInstanceTypes",
                        "ec2:DescribeInstanceStatus",
                        "ec2:DescribeImages",
                        "ec2:DescribeAvailabilityZones"
                    ],
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "EC2Read"
                },
                {
                    "Action": [
                        "ec2:TerminateInstances",
                        "ec2:RunInstances",
                        "ec2:CreateTags",
                        "ec2:CreateLaunchTemplate",
                        "ec2:CreateFleet"
                    ],
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "EC2Provision"
                },
                {
                    "Action": "ec2:DeleteLaunchTemplate",
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "EC2DeleteLaunchTemplate"
                },
                {
                    "Action": "iam:PassRole",
                    "Effect": "Allow",
                    "Resource": "arn:aws:iam::176777036414:role/ecommerce-dev-cluster-karpenter-node",
                    "Sid": "PassNodeRole"
                },
                {
                    "Action": "eks:DescribeCluster",
                    "Effect": "Allow",
                    "Resource": "arn:aws:eks:us-east-1:176777036414:cluster/ecommerce-dev-cluster",
                    "Sid": "DescribeCluster"
                },
                {
                    "Action": "pricing:GetProducts",
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "Pricing"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": false,
        "CreateDate": "2026-09-27T09:50:18+00:00"
    }
}
