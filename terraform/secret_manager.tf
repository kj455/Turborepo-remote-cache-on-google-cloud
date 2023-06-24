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