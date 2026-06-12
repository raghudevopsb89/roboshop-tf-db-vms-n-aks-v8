data "external" "grafana_secret" {
  program = ["bash", "${path.module}/get_password.sh"]
}

output "grafana_admin_password" {
  # base64decode() takes care of the decoding inside Terraform
  value = base64decode(data.external.grafana_secret.result["password"])
}

