# Cannot create external OAuth2.0 Sign-in Page using terraform
# Cannot create external OAuth2.0 Credential using terraform
# Cannot add Allowed Domains to Backend IAP Credential using Terraform
# See examples and explaination here: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/blueprints/serverless/cloud-run-explore

# Build iap robot account
resource "google_project_service_identity" "iap_sa" {
  provider = google-beta
  project  = module.project_factory.project_id
  service  = "iap.googleapis.com"
}

# Grant required permissions to Cloud Run service account
resource "google_project_iam_member" "iap_web_access" {
  for_each = toset(var.iap_users)
  project  = module.project_factory.project_id
  role     = "roles/iap.httpsResourceAccessor"
  member   = each.key
}
