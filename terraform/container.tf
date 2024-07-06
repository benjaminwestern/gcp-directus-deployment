resource "google_service_account" "cloud_run_service" {
  provider     = google-beta.australia-southeast1
  account_id   = var.service_name
  display_name = "Cloud Run Service Account for ${var.service_name}"
}

resource "google_project_iam_member" "project_cr_roles" {
  for_each   = toset(var.cr_project_roles)
  provider   = google-beta.australia-southeast1
  project    = module.project_factory.project_id
  role       = each.key
  member     = "serviceAccount:${google_service_account.cloud_run_service.email}"
  depends_on = [google_service_account.cloud_run_service]
}

resource "google_cloud_run_v2_service" "cloud_run_service" {
  provider     = google-beta.australia-southeast1
  name         = var.service_name
  location     = var.deployment_location
  launch_stage = "GA"

  template {
    scaling {
      max_instance_count = 20
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.mysql_instance.connection_name]
      }
    }
    vpc_access {
      connector = google_vpc_access_connector.serverless_vpc_connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
    # Can also connect to the VPC this way:
    # vpc_access {
    #   network_interfaces {
    #     network    = "projects/<project>/regions/<region>/sql-vpc"
    #     subnetwork = "projects/<project>/regions/<region>/subnetworks/sql-vpc-ase1"
    #   }
    #   egress = "PRIVATE_RANGES_ONLY"
    # }
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    containers {
      resources {
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
        cpu_idle = true
      }
      image = "directus/directus:10.10.4"
      ports {
        name           = "http1"
        container_port = 8055
      }
      dynamic "env" {
        for_each = {
          "ENVIRONMENT"                 = "production",
          "DB_DRIVER"                   = "mysql",
          "DB_HOST"                     = "cloudsql/${google_sql_database_instance.mysql_instance.connection_name}", # Required format for Directus Database e.g /cloudsql/directus-project:us-central1:directus-db
          "DB_PORT"                     = "3306",
          "DB_DATABASE"                 = var.database_name,
          "DB_USER"                     = google_sql_user.users.name,
          "ADMIN_EMAIL"                 = var.directus_admin_email
          "STORAGE_LOCATIONS"           = "gcs"
          "STORAGE_GCS_DRIVER"          = "gcs"
          "STORAGE_GCS_BUCKET"          = google_storage_bucket.assets.name
          "DB_SSL__REJECT_UNAUTHORIZED" = true
        }
        content {
          name  = env.key
          value = env.value
        }
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.password_secret.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.extra_password_secrets["directus-key"].secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.extra_password_secrets["directus-secret"].secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "ADMIN_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.extra_password_secrets["directus-admin"].secret_id
            version = "latest"
          }
        }
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

    }
    service_account = google_service_account.cloud_run_service.email
  }
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # Ignore changes to images as these are managed by GitHub Actions
      template[0].labels,              # Ignore changes to labels as these can change when the service is updated
      client,                          # Ignore changes to the client as this will update depending on CLI, TF or Console updates.
      client_version,                  # Ignore changes to the client version as this will update depending on CLI, TF or Console updates.
      template[0].revision             # Ignore changes to the revision as this will update depending on the image
    ]
  }
  depends_on = [google_vpc_access_connector.serverless_vpc_connector, google_sql_user.users, google_project_iam_member.project_cr_roles, google_secret_manager_secret_version.extra_password_secret_version]
}

# Allows anyone to invoke the website and the IAP robot account
data "google_iam_policy" "auth" {
  provider = google-beta.australia-southeast1
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
      "serviceAccount:service-${module.project_factory.project_number}@gcp-sa-iap.iam.gserviceaccount.com"
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  provider    = google-beta.australia-southeast1
  location    = google_cloud_run_v2_service.cloud_run_service.location
  project     = google_cloud_run_v2_service.cloud_run_service.project
  service     = google_cloud_run_v2_service.cloud_run_service.name
  policy_data = data.google_iam_policy.auth.policy_data
  depends_on = [
    google_project_iam_member.project_cr_roles,
    google_cloud_run_v2_service.cloud_run_service
  ]
  lifecycle {
    ignore_changes = [
      service,
      project,
      location
    ]
  }
}

