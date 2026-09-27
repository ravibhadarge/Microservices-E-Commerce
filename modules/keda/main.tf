resource "helm_release" "keda" {
  name       = "keda"
  namespace  = var.namespace
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.keda_version

  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      operator = {
        replicaCount = 1

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }

          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      metricServer = {
        replicaCount = 1

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }

          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      webhooks = {
        replicaCount = 1

        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }

          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }
    })
  ]
}
