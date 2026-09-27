#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="$1"
INSTANCE_PROFILE="$2"
SECURITY_GROUP_ID="$3"
SUBNET_1="$4"
SUBNET_2="$5"

export KARPENTER_INSTANCE_PROFILE="$INSTANCE_PROFILE"
export SECURITY_GROUP_ID="$SECURITY_GROUP_ID"
export SUBNET_1="$SUBNET_1"
export SUBNET_2="$SUBNET_2"

envsubst < nodeclass.yaml | kubectl apply -f -
kubectl apply -f nodepool.yaml
