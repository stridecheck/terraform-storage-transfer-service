/**
# main.tf — Event-driven Storage Transfer (prefix-based), TF 1.5.7 compatible
# 1) Enable Service Usage API (fixes the 403 in your error)
gcloud services enable serviceusage.googleapis.com \
  --project=pj-na2-hub-control-01-prd-zzf

# 2) Enable the other APIs you need for your TF config
gcloud services enable storage.googleapis.com pubsub.googleapis.com storagetransfer.googleapis.com \
  --project=pj-na2-hub-control-01-prd-zzf

# 3) (Optional) Verify they’re enabled
gcloud services list --enabled --project=pj-na2-hub-control-01-prd-zzf | grep -E 'serviceusage|storage|pubsub|storagetransfer'
 */

terraform {
  required_version = "~> 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.29.0, < 6.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- Enable required APIs ---
# Split STS so it can be target-applied first if needed.
resource "google_project_service" "sts_api" {
  project            = var.project_id
  service            = "storagetransfer.googleapis.com"
  disable_on_destroy = false
}

locals {
  other_apis = toset([
    "pubsub.googleapis.com",
    "storage.googleapis.com",
  ])
}

resource "google_project_service" "other_apis" {
  for_each           = local.other_apis
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Lookups & service accounts ---
data "google_project" "central" {
  project_id = var.project_id
}

# GCS internal SA used for bucket notifications -> Pub/Sub
data "google_storage_project_service_account" "gcs_sa" {}

# Storage Transfer managed SA (created/returned after API enable)
data "google_storage_transfer_project_service_account" "sts" {
  project    = var.project_id
  depends_on = [google_project_service.sts_api]
}

# --- Pub/Sub topic for source bucket events ---
resource "google_pubsub_topic" "src_events" {
  name    = "gcs-src-events"
  project = var.project_id
}

# Allow GCS to publish to the topic
resource "google_pubsub_topic_iam_member" "topic_pub" {
  topic  = google_pubsub_topic.src_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

# Bucket notification: OBJECT_FINALIZE -> Pub/Sub topic
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
 # Allow deletion even if objects (and versions) exist
  force_destroy = true
}

# --- IAM: STS agent permissions ---
# Source: needs object read + bucket metadata read (buckets.get)
resource "google_storage_bucket_iam_member" "source_view" {
  bucket = var.source_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}

# Use legacyBucketReader (bucket-level role that includes storage.buckets.get)
resource "google_storage_bucket_iam_member" "source_bucket_meta" {
  bucket = var.source_bucket
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}

# Destinations: needs object admin (write) + bucket metadata read
resource "google_storage_bucket_iam_member" "dest_write" {
  for_each = local.destinations
  bucket   = google_storage_bucket.dest[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}

resource "google_storage_bucket_iam_member" "dest_bucket_meta" {
  for_each = local.destinations
  bucket   = google_storage_bucket.dest[each.key].name
  role     = "roles/storage.legacyBucketReader"
  member   = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}

# --- Per-job subscription and event-driven STS job ---
resource "google_pubsub_subscription" "sub" {
  for_each                     = var.jobs
  name                         = "sts-${each.key}"
  topic                        = google_pubsub_topic.src_events.name
  ack_deadline_seconds         = 300
  message_retention_duration   = "604800s" # 7 days
}

# Allow STS to consume from each subscription
resource "google_pubsub_subscription_iam_member" "sub_read" {
  for_each     = var.jobs
  subscription = google_pubsub_subscription.sub[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${data.google_storage_transfer_project_service_account.sts.email}"
}

resource "google_storage_transfer_job" "job" {
  for_each    = var.jobs
  project     = var.project_id
  description = "Event-driven ${var.source_bucket} → ${each.value.dest_bucket} (${join(",", each.value.include_prefixes)})"
  status      = "ENABLED"

  # Event-driven: STS listens to this subscription
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
    google_project_service.sts_api,
    google_pubsub_subscription_iam_member.sub_read,
    google_storage_notification.src_notify,
    google_storage_bucket.dest,
    google_storage_bucket_iam_member.source_view,
    google_storage_bucket_iam_member.source_bucket_meta,
    google_storage_bucket_iam_member.dest_write,
    google_storage_bucket_iam_member.dest_bucket_meta,
  ]
}
