terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = { source = "hashicorp/google", version = ">= 5.29.0" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- Enable required APIs ---
locals {
  apis = toset([
    "storagetransfer.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com"
  ])
}

resource "google_project_service" "apis" {
  for_each           = local.apis
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Lookups ---
data "google_project" "central" { project_id = var.project_id }

# GCS internal SA that publishes to Pub/Sub for bucket notifications
data "google_storage_project_service_account" "gcs_sa" {}

# STS service agent for this project (needs bucket/subscribe perms)
locals {
  sts_agent = "serviceAccount:project-${data.google_project.central.number}@storage-transfer-service.iam.gserviceaccount.com"
}

# --- Pub/Sub topic for source bucket events ---
resource "google_pubsub_topic" "src_events" {
  name    = "gcs-src-events"
  project = var.project_id
}

# Allow GCS to publish to topic
resource "google_pubsub_topic_iam_member" "topic_pub" {
  topic  = google_pubsub_topic.src_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

# Bucket notification: OBJECT_FINALIZE → Pub/Sub topic
resource "google_storage_notification" "src_notify" {
  bucket         = var.source_bucket
  topic          = google_pubsub_topic.src_events.id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_member.topic_pub]
}

# --- Create unique destination buckets (dedup if multiple jobs share one) ---
locals {
  destinations = {
    for k, j in var.jobs : j.dest_bucket => {
      project = j.dest_project
      bucket  = j.dest_bucket
    }
  }
}

resource "google_storage_bucket" "dest" {
  for_each                    = local.destinations
  name                        = each.value.bucket
  project                     = each.value.project
  location                    = var.region
  uniform_bucket_level_access = true
  versioning { enabled = true }
}

# --- IAM: let STS agent read source + write destinations ---
resource "google_storage_bucket_iam_member" "source_view" {
  bucket = var.source_bucket
  role   = "roles/storage.objectViewer"
  member = local.sts_agent
}

resource "google_storage_bucket_iam_member" "dest_write" {
  for_each = local.destinations
  bucket   = google_storage_bucket.dest[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = local.sts_agent
}

# --- Per-job subscription and event-driven STS job ---
resource "google_pubsub_subscription" "sub" {
  for_each              = var.jobs
  name                  = "sts-${each.key}"
  topic                 = google_pubsub_topic.src_events.name
  ack_deadline_seconds  = 300
  message_retention_duration = "604800s" # 7 days buffer
}

# STS must be able to consume from each subscription
resource "google_pubsub_subscription_iam_member" "sub_read" {
  for_each     = var.jobs
  subscription = google_pubsub_subscription.sub[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = local.sts_agent
}

resource "google_storage_transfer_job" "job" {
  for_each    = var.jobs
  project     = var.project_id
  description = "Event-driven ${var.source_bucket} → ${each.value.dest_bucket} (${join(",", each.value.include_prefixes)})"
  status      = "ENABLED"

  # Event-driven: STS listens to the specific subscription
  event_stream {
    name = "projects/${var.project_id}/subscriptions/${google_pubsub_subscription.sub[each.key].name}"
  }

  transfer_spec {
    gcs_data_source { bucket_name = var.source_bucket }
    gcs_data_sink   { bucket_name = each.value.dest_bucket }

    object_conditions {
      include_prefixes = each.value.include_prefixes
      exclude_prefixes = each.value.exclude_prefixes
    }

    transfer_options {
      overwrite_objects_already_existing_in_sink = var.overwrite_sink
      delete_objects_unique_in_sink              = false
      delete_objects_from_source_after_transfer  = var.delete_source_after_transfer
    }
  }

  depends_on = [
    google_pubsub_subscription_iam_member.sub_read,
    google_storage_notification.src_notify,
    google_storage_bucket.dest,
    google_storage_bucket_iam_member.source_view,
    google_storage_bucket_iam_member.dest_write
  ]
}
