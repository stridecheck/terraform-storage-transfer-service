project_id    = "central-project-id"
region        = "northamerica-northeast2"
source_bucket = "central-intake-bucket"

# Multiple files/prefixes, multiple destinations
jobs = {
  # Capital Markets: keep "cm-" in filename
  capital_markets = {
    dest_project     = "prj-capital-markets-123"
    dest_bucket      = "org-cm-ingest-na2"
    include_prefixes = ["cm-"]          # matches cm-report.csv, cm-foo/bar.txt, etc.
    exclude_prefixes = []               # optional
  }

  # HR example: multiple prefixes to same destination
  hr = {
    dest_project     = "prj-hr-456"
    dest_bucket      = "org-hr-ingest-na2"
    include_prefixes = ["hr-", "people-"]
  }

  # AI Apps: two prefixes to one bucket
  aiapps = {
    dest_project     = "pj-na2-aiapps-01-prd"
    dest_bucket      = "aiapps-drop-na2"
    include_prefixes = ["na2-", "ai-"]
  }
}

overwrite_sink               = true
delete_source_after_transfer = false
