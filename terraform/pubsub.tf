resource "google_pubsub_topic" "gcr" {
  name = "gcr" # Artifact Registry publishes messages to the "gcr" topic. See https://cloud.google.com/artifact-registry/docs/configure-notifications
}