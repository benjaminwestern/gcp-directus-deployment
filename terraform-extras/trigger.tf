resource "google_cloudbuild_trigger" "main" {
  location    = local.region
  project     = local.project
  name        = "${local.github_repository_name}-main"
  description = "Builds when a branch is pushed to main."

  repository_event_config {
    repository = google_cloudbuildv2_repository.repository.id
    push {
      branch = "main"
    }
  }

  included_files = ["/"]
  # Ensure you update the variables in the workflow.yaml that are relevant to the build
  filename = "terraform-extras/workflow.yaml"
}
