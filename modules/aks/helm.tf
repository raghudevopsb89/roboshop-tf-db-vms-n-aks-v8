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

## External DNS Helm chart secret
resource "null_resource" "external-dns-secret" {
  depends_on = [
    null_resource.kube-config
  ]

  provisioner "local-exec" {
    command = <<EOF
echo '{
  "tenantId": "229f3fa3-57f3-4e2c-852f-24b7bf512640",
  "subscriptionId": "3f2e42e1-ca06-4a99-8c56-be8d8ba306db",
  "resourceGroup": "${var.rg_name}",
  "aadClientId": "${data.azurerm_key_vault_secret.ClientID.value}",
  "aadClientSecret": "${data.azurerm_key_vault_secret.ClientPassword.value}"
}' >/tmp/azure.json
kubectl create secret generic azure-config-file --namespace devops --from-file /tmp/azure.json
EOF
  }

}

resource "helm_release" "external_dns" {

  depends_on = [null_resource.external-dns-secret]

  chart      = "external-dns"
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"

  values = [
    yamlencode({
      provider = { name = "azure" }
    })
  ]

}

