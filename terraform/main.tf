# Create project for services to be hosted in
module "project_factory" {
  source            = "terraform-google-modules/project-factory/google"
  version           = "15.0.1"
  name              = var.project_name
  random_project_id = true
  org_id            = var.org_id
  create_project_sa = false
  # Usage Buckets have to be provisioned POST the initial deployment if required
  # usage_bucket_name   = var.service_name
  # usage_bucket_prefix = "usage"
  billing_account = var.billing_account_id
  activate_apis   = var.apis_to_enable
  # Billing budgets require additional permissions on the billing account
  # budget_amount               = 100
  # budget_display_name         = var.service_name
  # budget_alert_spent_percents = [50, 90]
}

resource "null_resource" "org" {
  triggers = { trigger = "build" }
  provisioner "local-exec" {
    command = <<EOT
      echo "terraform {
        backend \"gcs\" {
          bucket = \"${google_storage_bucket.terraform_state_bucket.name}\"
          prefix = \"terraform/state\"
        }
        required_providers {
          google = {
            source  = \"hashicorp/google\"
            version = \"~> 5.36.0\"
          }
          google-beta = {
            source  = \"hashicorp/google-beta\"
            version = \"~> 5.36.0\"
          }
          time = {
            source  = \"hashicorp/time\"
            version = \"~> 0.11.2\"
          }
          random = {
            source  = \"hashicorp/random\"
            version = \"~> 3.6.2\"
          }
          null = {
            source  = \"hashicorp/null\"
            version = \"~> 3.2.2\"
          }
        }
      }" > ./NEW_backend.tf
    EOT
  }
  depends_on = [
    module.project_factory
  ]
}
