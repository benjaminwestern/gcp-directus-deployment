resource "google_secret_manager_secret" "github" {
  secret_id = "github-oauthtoken"
  labels    = {}
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "github_token" {
  provider    = google-beta
  secret      = google_secret_manager_secret.github.id
  secret_data = local.super_secret_private_key
  depends_on  = [google_secret_manager_secret.github]
}

resource "google_secret_manager_secret_iam_member" "github_member" {
  project   = google_secret_manager_secret.github.project
  secret_id = google_secret_manager_secret.github.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${local.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_cloudbuildv2_connection" "github" {
  project  = local.project
  location = local.region
  name     = local.github_repository_name
  github_config {
    app_installation_id = 12345678
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github_token.name
    }
  }
}

resource "google_cloudbuildv2_repository" "repository" {
  project           = local.project
  location          = local.region
  name              = "repo-${github_repository_name}"
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = local.github_repo_url
}
