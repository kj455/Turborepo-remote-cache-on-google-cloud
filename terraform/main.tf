terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.69.1"
    }
  }
}

provider "google" {
  credentials = file("../credentials.json")
  project     = var.project_id
  region      = var.region
}

resource "google_storage_bucket" "turborepo-remote-cache" {
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = var.bucket_lifecycle_age
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "turborepo-remote-cache-fn" {
  name          = "${var.bucket_name}-fn"
  location      = var.bucket_location
  force_destroy = true
}

resource "google_service_account" "gcs-admin" {
  account_id = "turborepo-remote-cache-runner"
}

resource "google_service_account_key" "gcs-admin-key" {
  service_account_id = google_service_account.gcs-admin.name
}

locals {
  decoded_key      = jsondecode(base64decode(google_service_account_key.gcs-admin-key.private_key))
  run_service_name = "turborepo-remote-cache-runner"
}

resource "google_project_iam_member" "gcs-admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gcs-admin.email}"
}

resource "google_pubsub_topic" "gcr" {
  name = "gcr"
}

resource "google_project_service" "artifacts" {
  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "remote-cache-repo" {
  location      = var.region
  repository_id = "turborepo-remote-cache-repo"
  format        = "DOCKER"

  depends_on = [google_project_service.artifacts]
}

resource "google_project_service" "secret-manager" {
  service = "secretmanager.googleapis.com"
}

resource "google_secret_manager_secret" "sa_key_secret" {
  secret_id = "sa-key-secret"
  labels = {
    label = "sa-key-secret"
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secret-manager]
}

resource "google_secret_manager_secret_version" "sa_key_secret_version" {
  secret      = google_secret_manager_secret.sa_key_secret.id
  secret_data = local.decoded_key.private_key

  depends_on = [google_project_service.secret-manager]
}

data "archive_file" "functions" {
  type        = "zip"
  source_dir  = "../functions"
  output_path = "../functions.zip"
}

resource "google_storage_bucket_object" "archive" {
  name   = "functions_${data.archive_file.functions.output_md5}.zip"
  bucket = google_storage_bucket.turborepo-remote-cache-fn.name
  source = data.archive_file.functions.output_path
}

resource "google_project_iam_member" "function_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_cloudfunctions_function.revision-creator.service_account_email}"
}

resource "google_cloudfunctions_function" "revision-creator" {
  name        = "revision-creator-function"
  description = "Function to create Cloud Run revision"
  runtime     = "nodejs18"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.turborepo-remote-cache-fn.name
  source_archive_object = google_storage_bucket_object.archive.output_name
  entry_point           = "createRevision"

  environment_variables = {
    PROJECT_ID                  = var.project_id
    LOCATION                    = var.region
    SERVICE_ID                  = local.run_service_name
    TURBO_TOKEN                 = var.turbo_token
    GCS_BUCKET_NAME             = var.bucket_name
    GCS_CLIENT_EMAIL            = google_service_account.gcs-admin.email
    GCS_PRIVATE_KEY_SECRET_NAME = google_secret_manager_secret.sa_key_secret.secret_id
    SOURCE_SHA                  = data.archive_file.functions.output_md5 # necessary to trigger function update when archive changes
  }

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.gcr.id
    failure_policy {
      retry = true
    }
  }
}

resource "google_cloud_run_service" "default" {
  name     = local.run_service_name
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello" # Temporarily use Google's Hello World image. This will be replaced by Cloud Functions.
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  count = var.allow_unauthenticated ? 1 : 0

  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  count = var.allow_unauthenticated ? 1 : 0

  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth[0].policy_data
}