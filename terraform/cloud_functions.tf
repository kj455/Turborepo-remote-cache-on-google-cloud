data "archive_file" "functions" {
  type        = "zip"
  source_dir  = "../functions"
  output_path = "../functions.zip"
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

resource "google_project_iam_member" "function_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_cloudfunctions_function.revision-creator.service_account_email}"
}