locals {
  # This can be inherited from the core modules
  project        = "project_id"
  project_number = "1234567890"
  region         = "australia-southeast1"

  # New Required Variables
  artifact_respository_id  = "enterprises-docker"
  github_repository_name   = "repo-name"
  github_organisation_name = "organisation-name"
  github_repo_url          = "https://github.com/${local.github_organisation_name}/${local.github_repository_name}.git"
  super_secret_private_key = "FAKE SSH KEY CAN BE PASSED AS SECRET VARIABLE"
}
