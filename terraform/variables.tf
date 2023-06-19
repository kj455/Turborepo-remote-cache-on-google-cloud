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

variable "turbo_token" {
  description = "The token for Turborepo custom remote cache. Details: https://turbo.build/repo/docs/core-concepts/remote-caching#custom-remote-caches"
}