resource "google_project_service" "artifacts" {
  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "remote-cache-repo" {
  location      = var.region
  repository_id = "turborepo-remote-cache-repo"
  format        = "DOCKER"

  depends_on = [google_project_service.artifacts]
}