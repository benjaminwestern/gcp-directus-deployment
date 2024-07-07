resource "google_sql_database_instance" "mysql_instance" {
  provider         = google-beta.australia-southeast1
  name             = "${var.service_name}-mysql-instance"
  database_version = "MYSQL_8_0"
  region           = var.deployment_location
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      private_network                               = google_compute_network.vpc_network.id
      ipv4_enabled                                  = false
      enable_private_path_for_google_cloud_services = true
    }
    insights_config {
      query_insights_enabled = true
    }
    # backup daily
    backup_configuration {
      binary_log_enabled             = true
      enabled                        = true
      start_time                     = "00:00"
      location                       = var.backup_location
      transaction_log_retention_days = 7
      backup_retention_settings {
        retention_unit   = "COUNT"
        retained_backups = 7
      }
    }
  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "mysql_database" {
  provider   = google-beta.australia-southeast1
  name       = var.database_name
  instance   = google_sql_database_instance.mysql_instance.name
  depends_on = [google_sql_database_instance.mysql_instance]
}

# randomly generate a password for the root user and then store it in gc secret manager
resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "password_secret" {
  provider  = google-beta
  project   = module.project_factory.project_id
  secret_id = "database-password"
  replication {
    user_managed {
      replicas {
        location = var.backup_location
      }
    }
  }
  depends_on = [random_password.root_password]
}

resource "google_secret_manager_secret_version" "password_secret_version" {
  provider    = google-beta
  secret      = google_secret_manager_secret.password_secret.id
  secret_data = random_password.root_password.result
  depends_on  = [google_secret_manager_secret.password_secret]
}

resource "google_sql_user" "users" {
  provider   = google-beta.australia-southeast1
  name       = "directus"
  host       = "%"
  instance   = google_sql_database_instance.mysql_instance.name
  password   = random_password.root_password.result
  depends_on = [google_secret_manager_secret_version.password_secret_version, google_sql_database.mysql_database]
}
