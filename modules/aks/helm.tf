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
}

