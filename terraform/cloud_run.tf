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