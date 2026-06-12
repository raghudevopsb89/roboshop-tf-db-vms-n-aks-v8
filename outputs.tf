data "external" "grafana_secret" {
  depends_on = [module.aks]
  program    = ["bash", "${path.root}/k8s-secrets.sh"]
}

output "grafana_admin_password" {
  # base64decode() takes care of the decoding inside Terraform
  value = base64decode(data.external.grafana_secret.result["password"])
}

