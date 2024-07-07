variable "oauth2_client_id" {
  description = "OAuth2 client secret"
  type        = string
  sensitive   = true
}

variable "oauth2_client_secret" {
  description = "OAuth2 client secret"
  type        = string
  sensitive   = true
}

variable "apis_to_enable" {
  description = "APIs that are required for the project services listed in this Terraform to function"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "run.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storagetransfer.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com",
  ]
}

variable "cr_project_roles" {
  description = "Roles required on the project for the cloud run service account"
  type        = list(string)
  default = [
    "roles/cloudsql.client",
    "roles/run.invoker",
    "roles/vpcaccess.user",
    "roles/secretmanager.secretAccessor",
  ]
}

variable "project_name" {
  description = "Name of the project to Deploy"
  type        = string
  default     = "ben-gcp-directus" # name must be 4 to 30 characters with lowercase and uppercase letters, numbers, hyphen, single-quote, double-quote, space, and exclamation point
}

variable "org_id" {
  description = "ID of the GCP Organisation to deploy in"
  type        = string
}

variable "billing_account_id" {
  description = "ID of the GCP Billing Account to use for deployment"
  type        = string
}

variable "deployment_location" {
  description = "Region used for services"
  type        = string
  default     = "australia-southeast1"
}

variable "backup_location" {
  description = "Backup region used for services"
  type        = string
  default     = "australia-southeast2"
}

variable "service_name" {
  description = "Name of the Cloud Run service being deployed"
  type        = string
  default     = "gcp-directus"
}

variable "database_name" {
  description = "Name of the MySQL Database to be deployed"
  type        = string
  default     = "database"
}

variable "core_domains" {
  description = "Domains to be utilised for the Load Balancer and SSL Certificates"
  type        = list(string)
  default     = ["directus.example.com"]
}

variable "admin_domains" {
  description = "Domains to be utilised for the Load Balancer and SSL Certificates"
  type        = list(string)
  default     = ["admin-directus.example.com"]
}

variable "iap_users" {
  description = "List of users, groups or service accounts that can access the IAP Web Application"
  type        = list(string)
  default     = ["user:ben@example.com"] # For groups use 'group:', for service accounts use 'serviceAccount:'
}

variable "directus_admin_email" {
  description = "Admin user"
  type        = string
  default     = "ben@example.com"
}
