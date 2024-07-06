provider "google" {
  region = "australia-southeast1"
}

provider "google" {
  project = module.project_factory.project_id
  alias   = "australia-southeast1"
  region  = "australia-southeast1"
}

provider "google-beta" {
  project = module.project_factory.project_id
  alias   = "australia-southeast1"
  region  = "australia-southeast1"
}
