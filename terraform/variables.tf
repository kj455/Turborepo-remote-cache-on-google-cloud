variable "project_id" {
  description = "The ID of the project in which the resource belongs"
}

variable "region" {
  description = "The region in which the resource belongs"
  default     = "asia-northeast1"
}

variable "bucket_name" {
  description = "The name of the bucket"
}

variable "bucket_location" {
  description = "The location of the bucket."
  default     = "ASIA-NORTHEAST1"
}

variable "turbo_token" {
  description = "The token of the turborepo"
}