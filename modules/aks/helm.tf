resource "null_resource" "kube-config" {

  depends_on = [azurerm_kubernetes_cluster_node_pool.pool1]

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group denmark-east-rg --name roboshop-${var.env} --overwrite-existing"
  }
}

resource "helm_release" "traefik_ingress" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
}


