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
resource "google_storage_transfer_job" "transfer_job" {
  provider    = google-beta.australia-southeast1
  project     = module.project_factory.project_id
  description = "${var.service_name} Job to backup core public bucket"
  schedule {
    # Create a schedule that doesn't expire
    schedule_start_date {
      year  = 2021
      month = 1
      day   = 1
    }
    start_time_of_day {
      hours   = 23
      minutes = 30
      seconds = 0
      nanos   = 0
    }
    # Repeat every 24 hours
    repeat_interval = "86400s"
  }

  transfer_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.bucket.name
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.bucket_backup.name
    }
    object_conditions {
      # Objects must be older than 24 hours
      min_time_elapsed_since_last_modification = "86400s"
    }
    transfer_options {
      overwrite_when = "DIFFERENT"
      # overwrite_objects_already_existing_in_sink = false
    }
  }
  depends_on = [google_storage_bucket.bucket, google_storage_bucket.bucket_backup, google_storage_bucket_iam_member.storage_transfer_public_permissions, google_storage_bucket_iam_member.storage_transfer_backup_permissions]
}

resource "google_storage_bucket_iam_member" "bucket_public" {
  provider   = google-beta.australia-southeast1
  bucket     = google_storage_bucket.bucket.name
  role       = "roles/storage.objectViewer"
  member     = "allUsers"
  depends_on = [google_storage_bucket.bucket]
}
resource "google_storage_bucket_iam_member" "storage_transfer_public_permissions" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:project-${module.project_factory.project_number}@storage-transfer-service.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "storage_transfer_backup_permissions" {
  bucket = google_storage_bucket.bucket_backup.name
  role   = "roles/storage.admin"
  member = "serviceAccount:project-${module.project_factory.project_number}@storage-transfer-service.iam.gserviceaccount.com"
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
