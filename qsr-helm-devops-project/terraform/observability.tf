resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [yamlencode({
    server = {
      service = {
        type = "ClusterIP"
      }
    }
    configs = {
      params = {
        "server.insecure" = true
      }
    }
  })]

  depends_on = [module.eks]
}

resource "helm_release" "kube_prometheus_stack" {
  count = var.install_observability ? 1 : 0

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
  timeout          = 1200

  values = [yamlencode({
    grafana = {
      service = {
        type = "ClusterIP"
      }
    }
    prometheus = {
      prometheusSpec = {
        serviceMonitorSelectorNilUsesHelmValues = false
        serviceMonitorSelector = {}
        serviceMonitorNamespaceSelector = {}
      }
    }
  })]

  depends_on = [module.eks]
}
