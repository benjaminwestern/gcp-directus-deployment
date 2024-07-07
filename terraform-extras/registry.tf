resource "google_artifact_registry_repository" "core_docker_registry" {
  location               = local.region
  repository_id          = local.artifact_respository_id
  description            = "Docker registry for all container images utilised across the product"
  format                 = "DOCKER"
  cleanup_policy_dry_run = true
  docker_config {
    immutable_tags = false
  }
  # You can add cleanup policies
  # cleanup_policies {
  #   id     = "delete-prerelease"
  #   action = "DELETE"
  #   condition {
  #     tag_state    = "TAGGED"
  #     tag_prefixes = ["alpha", "v0"]
  #     older_than   = "2592000s"
  #   }
  # }
  # cleanup_policies {
  #   id     = "keep-tagged-release"
  #   action = "KEEP"
  #   condition {
  #     tag_state             = "TAGGED"
  #     tag_prefixes          = ["release"]
  #     package_name_prefixes = ["webapp", "mobile"]
  #   }
  # }
  # cleanup_policies {
  #   id     = "keep-minimum-versions"
  #   action = "KEEP"
  #   most_recent_versions {
  #     package_name_prefixes = ["webapp", "mobile", "sandbox"]
  #     keep_count            = 5
  #   }
  # }
}
