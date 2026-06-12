#!/bin/bash

# Extract the value using jq with the correct bracket notation
PASSWORD=$(kubectl get secrets pstack-grafana -o json | jq '.data["admin-password"]')

# Terraform's external provider expects a valid JSON object as stdout
echo "{\"password\": $PASSWORD}"

