# variables.tf

variable "project_id" {
  type        = string
  description = "Central project that owns Pub/Sub & STS jobs."
}

variable "region" {
  type        = string
  default     = "northamerica-northeast1"
}

variable "source_bucket" {
  type        = string
  description = "Existing centralized intake GCS bucket (event source)."
}

# One job (destination) can match multiple prefixes
variable "jobs" {
  description = "Map of transfer jobs keyed by a short name."
  type = map(object({
    dest_project     = string
    dest_bucket      = string
    include_prefixes = list(string) # e.g., ["cm-", "cm_"]
    exclude_prefixes = list(string) # use [] if not needed
  }))
}

variable "overwrite_sink" {
  type        = bool
  default     = true
  description = "Overwrite objects already existing in destination."
}

variable "delete_source_after_transfer" {
  type        = bool
  default     = false
  description = "Delete source objects after successful transfer."
}
