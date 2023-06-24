resource "google_service_account" "gcs-admin" {
  account_id = "turborepo-remote-cache-runner"
}

resource "google_service_account_key" "gcs-admin-key" {
  service_account_id = google_service_account.gcs-admin.name
}

resource "google_project_iam_member" "gcs-admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gcs-admin.email}"
}