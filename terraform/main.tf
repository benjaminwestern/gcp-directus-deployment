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

# Create a External Global HTTPS Load Balancer for the Cloud Run service, backend has to be cloud run, needs SSL certificate 
resource "google_compute_ssl_policy" "prod_ssl_policy" {
  name    = "production-ssl-policy"
  project = module.project_factory.project_id
  profile = "MODERN"
}

# Create the A record for each domain once the LB is created so the SSL Cert can register
module "lb-http" {
  source                          = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version                         = "11.1.0"
  name                            = var.service_name
  project                         = module.project_factory.project_id
  ssl                             = true
  managed_ssl_certificate_domains = var.core_domains
  https_redirect                  = true
  labels                          = { "name" = var.service_name }
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  ssl_policy                      = google_compute_ssl_policy.prod_ssl_policy.self_link
  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      edge_security_policy    = null
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable = false
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
      protocol         = "HTTPS"
      port_name        = null
      compression_mode = null
    }
  }
  depends_on = [google_cloud_run_v2_service.cloud_run_service]
}

# Create the A record for each domain once the LB is created so the SSL Cert can register
module "lb-http-admin" {
  source                          = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version                         = "11.1.0"
  name                            = "${var.service_name}-admin-portal"
  project                         = module.project_factory.project_id
  ssl                             = true
  managed_ssl_certificate_domains = var.admin_domains
  https_redirect                  = true
  labels                          = { "name" = "${var.service_name}-admin-portal" }
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  ssl_policy                      = google_compute_ssl_policy.prod_ssl_policy.self_link
  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      edge_security_policy    = null
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null
      iap_config = {
        enable               = true
        oauth2_client_id     = var.oauth2_client_id
        oauth2_client_secret = var.oauth2_client_secret
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
      protocol         = "HTTPS"
      port_name        = null
      compression_mode = null
    }
  }
  depends_on = [google_cloud_run_v2_service.cloud_run_service]
}
