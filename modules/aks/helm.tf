resource "null_resource" "kube-config" {

  depends_on = [azurerm_kubernetes_cluster_node_pool.pool1]

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group denmark-east-rg --name roboshop-${var.env} --overwrite-existing"
  }
}

resource "helm_release" "traefik_ingress" {

  depends_on = [null_resource.kube-config]

  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
}

resource "helm_release" "prometheus_stack" {

  depends_on = [null_resource.kube-config, helm_release.traefik_ingress]

  name       = "pstack"
  repository = "oci://ghcr.io/prometheus-community/charts"
  chart      = "kube-prometheus-stack"

  values = [
    yamlencode({
      grafana = {
        ingress = {
          enabled          = true
          ingressClassName = "traefik"
          hosts            = ["grafana-${var.env}.rdevopsb89.online"]
          path             = "/"
          pathType         = "Prefix"
        }
      }
      prometheus = {
        ingress = {
          enabled          = true
          ingressClassName = "traefik"
          hosts            = ["prometheus-${var.env}.rdevopsb89.online"]
          paths            = ["/"]
          pathType         = "Prefix"
        }
      }
    })
  ]
}

resource "helm_release" "external_dns" {
  chart      = "external-dns"
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"

  values = [
    yamlencode({
      provider = { name = "azure" }
    })
  ]

}

