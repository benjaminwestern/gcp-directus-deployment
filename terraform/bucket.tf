resource "google_storage_bucket" "terraform_state_bucket" {
  provider                    = google-beta.australia-southeast1
  name                        = "tfstate-${module.project_factory.project_id}"
  location                    = var.deployment_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "assets" {
  provider                    = google-beta.australia-southeast1
  name                        = "assets-${module.project_factory.project_id}"
  location                    = var.deployment_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
}

# Only required if the Project Factory Usage is configured
# resource "google_storage_bucket" "usage_bucket" {
#   provider                    = google-beta.australia-southeast1
#   name                        = var.service_name
#   location                    = var.deployment_location
#   storage_class               = "STANDARD"
#   uniform_bucket_level_access = true
#   force_destroy               = true
# }

resource "google_storage_bucket" "bucket" {
  provider                    = google-beta.australia-southeast1
  name                        = "${var.service_name}-public-${module.project_factory.project_id}"
  location                    = var.deployment_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = false # make public
  force_destroy               = true
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket" "bucket_backup" {
  provider                    = google-beta.australia-southeast1
  name                        = "${var.service_name}-backup-${module.project_factory.project_id}"
  location                    = var.backup_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
}

# setup data transfer daily from bucket to bucket backup
# TODO This is broken right now
# resource "google_storage_transfer_job" "transfer_job" {
#   provider    = google-beta.australia-southeast1
#   name        = "${var.service_name}-backup-job"
#   description = "${var.service_name} Job to backup core bucket"
#   schedule {
#     schedule_start_date {
#       day   = 1
#       month = 1
#       year  = 2021
#     }
#     start_time_of_day {
#       hours   = 0
#       minutes = 0
#       seconds = 0
#       nanos   = 0
#     }
#     end_time_of_day {
#       hours   = 23
#       minutes = 59
#       seconds = 59
#     }
#     recurrence_period_days = 1
#   }
#   transfer_spec {
#     gcs_data_source {
#       bucket_name = google_storage_bucket.bucket.name
#     }
#     gcs_data_sink {
#       bucket_name = google_storage_bucket.bucket_backup.name
#     }
#     object_conditions {
#       min_time_elapsed_since_last_modification = "2592000s"
#     }
#     transfer_options {
#       overwrite_objects_already_existing_in_sink = true
#     }
#   }
#   depends_on = [google_storage_bucket.bucket, google_storage_bucket.bucket_backup]
# }

resource "google_storage_bucket_iam_member" "bucket_public" {
  provider   = google-beta.australia-southeast1
  bucket     = google_storage_bucket.bucket.name
  role       = "roles/storage.objectViewer"
  member     = "allUsers"
  depends_on = [google_storage_bucket.bucket]
}

resource "google_storage_bucket_iam_member" "cr_public_bucket_permissions" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.cloud_run_service.email}"
}

resource "google_storage_bucket_iam_member" "cr_assets_bucket_permissions" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.cloud_run_service.email}"
}
