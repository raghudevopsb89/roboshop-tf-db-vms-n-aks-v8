data "external" "grafana_secret" {
  depends_on = [module.aks]
  program    = ["bash", "${path.module}/get_password.sh"]
}

output "grafana_admin_password" {
  # base64decode() takes care of the decoding inside Terraform
  value = base64decode(data.external.grafana_secret.result["password"])
}

