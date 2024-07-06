locals {
  passwords_to_generate = ["directus-key", "directus-secret", "directus-admin"]
}

# randomly generate a password for the above list and then store it in gc secret manager
resource "random_password" "extra_passwords" {
  for_each = toset(local.passwords_to_generate)
  length   = 16
  special  = false
}

resource "google_secret_manager_secret" "extra_password_secrets" {
  for_each  = toset(local.passwords_to_generate)
  provider  = google-beta
  project   = module.project_factory.project_id
  secret_id = "${each.key}-secret"
  replication {
    user_managed {
      replicas {
        location = var.backup_location
      }
    }
  }
  depends_on = [random_password.extra_passwords]
}

resource "google_secret_manager_secret_version" "extra_password_secret_version" {
  for_each    = toset(local.passwords_to_generate)
  provider    = google-beta
  secret      = google_secret_manager_secret.extra_password_secrets[each.key].id
  secret_data = random_password.extra_passwords[each.key].result
  depends_on  = [google_secret_manager_secret.extra_password_secrets]
}
