variable "project_id" {
  description = "The ID of the project"
}

variable "region" {
  description = "The region where resources are located"
}

variable "bucket_name" {
  description = "The name of the bucket"
}

variable "bucket_location" {
  description = "The location of the bucket"
}

variable "bucket_lifecycle_age" {
  description = "The age of the bucket"
  default     = 7
}

variable "turbo_token" {
  description = "The token for Turborepo custom remote cache. Details: https://turbo.build/repo/docs/core-concepts/remote-caching#custom-remote-caches"
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access to the remote cache server on Cloud Run"
  default     = false
}
