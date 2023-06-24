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

resource "google_storage_bucket_object" "archive" {
  name   = "functions_${data.archive_file.functions.output_md5}.zip"
  bucket = google_storage_bucket.turborepo-remote-cache-fn.name
  source = data.archive_file.functions.output_path
}
